-- D03 · E-commerce: đơn hàng, tồn kho, thanh toán, state machine. DB: lab, schema d03.
DROP SCHEMA IF EXISTS d03 CASCADE;
CREATE SCHEMA d03;
SET search_path = d03;

CREATE TABLE users (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email text NOT NULL UNIQUE
);

CREATE TABLE products (
    id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku   text NOT NULL UNIQUE,
    name  text NOT NULL,
    price numeric(12,0) NOT NULL CHECK (price >= 0)        -- VND, không phần thập phân
);

-- Tồn kho tách khỏi products: dòng này bị UPDATE liên tục, products thì gần như chỉ đọc (tránh bloat/WAL thừa)
CREATE TABLE inventory (
    product_id bigint PRIMARY KEY REFERENCES products(id),
    on_hand    integer NOT NULL CHECK (on_hand >= 0),      -- hàng thực trong kho
    reserved   integer NOT NULL DEFAULT 0 CHECK (reserved >= 0),   -- đã giữ cho đơn pending
    CONSTRAINT inventory_reserved_le_on_hand CHECK (reserved <= on_hand)   -- lưới an toàn cuối cùng chống oversell
) WITH (fillfactor = 70);                                   -- chừa chỗ cho HOT update

-- State machine: bảng chuyển trạng thái hợp lệ + trigger. Rule nằm ở DB nên mọi service đều bị ràng buộc.
CREATE TABLE order_transitions (
    from_status text NOT NULL,
    to_status   text NOT NULL,
    PRIMARY KEY (from_status, to_status)
);
INSERT INTO order_transitions VALUES
    ('pending','paid'), ('pending','cancelled'),
    ('paid','shipped'), ('paid','refunded'),
    ('shipped','delivered'), ('delivered','refunded');

CREATE TABLE orders (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id         bigint NOT NULL REFERENCES users(id),
    idempotency_key text   NOT NULL,
    status          text   NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','paid','shipped','delivered','cancelled','refunded')),
    total_amount    numeric(14,0) NOT NULL CHECK (total_amount >= 0),
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    -- retry/double-submit của cùng user + cùng key trả về cùng đơn
    CONSTRAINT orders_idem_uk UNIQUE (user_id, idempotency_key)
);
CREATE INDEX orders_user_idx ON orders (user_id, created_at DESC);
-- Job hết hạn chỉ quan tâm đơn pending: partial index nhỏ xíu so với toàn bảng
CREATE INDEX orders_pending_idx ON orders (created_at) WHERE status = 'pending';

CREATE TABLE order_items (
    order_id   bigint   NOT NULL REFERENCES orders(id),
    line_no    smallint NOT NULL,
    product_id bigint   NOT NULL REFERENCES products(id),
    quantity   integer  NOT NULL CHECK (quantity > 0),
    unit_price numeric(12,0) NOT NULL,                    -- snapshot giá lúc mua
    PRIMARY KEY (order_id, line_no)
);

CREATE TABLE order_status_log (
    order_id   bigint NOT NULL REFERENCES orders(id),
    seq        bigint GENERATED ALWAYS AS IDENTITY,
    from_status text,
    to_status   text NOT NULL,
    at          timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (order_id, seq)
);

CREATE TABLE payments (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id     bigint NOT NULL REFERENCES orders(id),
    provider_ref text   NOT NULL,                          -- id giao dịch phía cổng thanh toán
    amount       numeric(14,0) NOT NULL CHECK (amount > 0),
    created_at   timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT payments_provider_ref_uk UNIQUE (provider_ref)   -- webhook gửi lại nhiều lần vẫn chỉ 1 dòng
);
CREATE INDEX payments_order_idx ON payments (order_id);

CREATE FUNCTION orders_guard_status() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        IF NOT EXISTS (SELECT 1 FROM order_transitions WHERE from_status = OLD.status AND to_status = NEW.status) THEN
            RAISE EXCEPTION 'chuyển trạng thái không hợp lệ: % -> %', OLD.status, NEW.status USING ERRCODE = 'check_violation';
        END IF;
        INSERT INTO order_status_log (order_id, from_status, to_status) VALUES (NEW.id, OLD.status, NEW.status);
        NEW.updated_at := now();
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER orders_status_guard BEFORE UPDATE OF status ON orders
    FOR EACH ROW EXECUTE FUNCTION orders_guard_status();

-- Đặt đơn: idempotent, giữ chỗ nguyên tử, khóa tồn kho theo thứ tự product_id (chống deadlock).
-- p_items: [{"product_id":1,"qty":2}, ...]. Hết hàng => exception 'OOS01', cả đơn rollback.
CREATE FUNCTION place_order(p_user bigint, p_key text, p_items jsonb) RETURNS bigint
LANGUAGE plpgsql AS $$
DECLARE
    v_order bigint; it record; n int := 0;
BEGIN
    INSERT INTO orders (user_id, idempotency_key, total_amount) VALUES (p_user, p_key, 0)
    ON CONFLICT (user_id, idempotency_key) DO NOTHING
    RETURNING id INTO v_order;
    IF v_order IS NULL THEN                                  -- request lặp: trả đơn cũ
        SELECT id INTO v_order FROM orders WHERE user_id = p_user AND idempotency_key = p_key;
        RETURN v_order;
    END IF;
    FOR it IN SELECT (e->>'product_id')::bigint AS pid, (e->>'qty')::int AS qty
              FROM jsonb_array_elements(p_items) e ORDER BY 1 LOOP       -- ORDER BY product_id: thứ tự khóa cố định
        UPDATE inventory SET reserved = reserved + it.qty
        WHERE product_id = it.pid AND on_hand - reserved >= it.qty;
        IF NOT FOUND THEN RAISE EXCEPTION 'hết hàng product %', it.pid USING ERRCODE = 'OOS01'; END IF;
        n := n + 1;
        INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price)
        SELECT v_order, n, p.id, it.qty, p.price FROM products p WHERE p.id = it.pid;
    END LOOP;
    UPDATE orders SET total_amount = (SELECT sum(quantity * unit_price) FROM order_items WHERE order_id = v_order)
    WHERE id = v_order;
    RETURN v_order;
END $$;

-- Webhook thanh toán: idempotent theo provider_ref, chỉ pending -> paid, đúng số tiền; trừ kho thật.
CREATE FUNCTION confirm_payment(p_order bigint, p_ref text, p_amount numeric) RETURNS boolean
LANGUAGE plpgsql AS $$
DECLARE v_new bigint;
BEGIN
    INSERT INTO payments (order_id, provider_ref, amount) VALUES (p_order, p_ref, p_amount)
    ON CONFLICT (provider_ref) DO NOTHING RETURNING id INTO v_new;
    IF v_new IS NULL THEN RETURN false; END IF;              -- đã xử lý rồi
    UPDATE orders SET status = 'paid' WHERE id = p_order AND status = 'pending' AND total_amount = p_amount;
    IF NOT FOUND THEN RAISE EXCEPTION 'không thể xác nhận đơn % (sai trạng thái hoặc sai số tiền)', p_order USING ERRCODE = 'check_violation'; END IF;
    PERFORM 1 FROM inventory WHERE product_id IN (SELECT product_id FROM order_items WHERE order_id = p_order)
    ORDER BY product_id FOR UPDATE;                          -- khóa theo thứ tự cố định rồi mới sửa
    UPDATE inventory i SET on_hand = i.on_hand - s.q, reserved = i.reserved - s.q
    FROM (SELECT product_id, sum(quantity) q FROM order_items WHERE order_id = p_order GROUP BY 1) s
    WHERE i.product_id = s.product_id;
    RETURN true;
END $$;

-- Hủy / hết hạn: trả lại phần giữ chỗ. Chỉ đơn đang pending mới có giữ chỗ.
CREATE FUNCTION cancel_pending(p_order bigint) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE orders SET status = 'cancelled' WHERE id = p_order AND status = 'pending';
    IF NOT FOUND THEN RETURN false; END IF;
    PERFORM 1 FROM inventory WHERE product_id IN (SELECT product_id FROM order_items WHERE order_id = p_order)
    ORDER BY product_id FOR UPDATE;                          -- khóa theo thứ tự cố định rồi mới sửa
    UPDATE inventory i SET reserved = i.reserved - s.q
    FROM (SELECT product_id, sum(quantity) q FROM order_items WHERE order_id = p_order GROUP BY 1) s
    WHERE i.product_id = s.product_id;
    RETURN true;
END $$;

-- Bảng phục vụ thí nghiệm concurrency (oversell.*.pgbench), không thuộc mô hình nghiệp vụ
CREATE TABLE demo_stock (product_id int PRIMARY KEY, on_hand int NOT NULL);
CREATE TABLE demo_sales (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, product_id int NOT NULL);
