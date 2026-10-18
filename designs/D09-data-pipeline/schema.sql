-- D09 · Data pipeline: OLTP vs OLAP, outbox, CDC, materialized aggregates. DB: lab, schema d09.
DROP SCHEMA IF EXISTS d09 CASCADE;
CREATE SCHEMA d09;
SET search_path = d09;

-- ===== OLTP =====
CREATE TABLE orders (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    bigint NOT NULL,
    total      numeric(14,0) NOT NULL CHECK (total >= 0),
    status     text NOT NULL DEFAULT 'placed',
    created_at timestamptz NOT NULL DEFAULT now()
);

-- Outbox: sự kiện được ghi CÙNG transaction với dữ liệu nghiệp vụ => không còn "dual write" (ghi DB xong mà publish hỏng, hoặc ngược lại)
CREATE TABLE outbox (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    aggregate_type    text   NOT NULL,
    aggregate_id      bigint NOT NULL,
    aggregate_version integer NOT NULL,                       -- thứ tự trong một aggregate (consumer dùng để bỏ qua bản cũ)
    event_type        text   NOT NULL,
    payload           jsonb  NOT NULL,
    created_at        timestamptz NOT NULL DEFAULT now(),
    published_at      timestamptz,
    CONSTRAINT outbox_agg_version_uk UNIQUE (aggregate_type, aggregate_id, aggregate_version)
);
CREATE INDEX outbox_pending_idx ON outbox (id) WHERE published_at IS NULL;   -- chỉ index phần chưa gửi: nhỏ và nóng

CREATE FUNCTION place_order(p_user bigint, p_items jsonb, p_placed_at timestamptz DEFAULT now()) RETURNS bigint
LANGUAGE plpgsql SET search_path = d09 AS $$
DECLARE v_id bigint; v_total numeric;
BEGIN
    SELECT sum((e->>'amount')::numeric) INTO v_total FROM jsonb_array_elements(p_items) e;
    INSERT INTO orders (user_id, total, created_at) VALUES (p_user, v_total, p_placed_at) RETURNING id INTO v_id;
    INSERT INTO outbox (aggregate_type, aggregate_id, aggregate_version, event_type, payload)
    VALUES ('order', v_id, 1, 'OrderPlaced',
            jsonb_build_object('order_id', v_id, 'user_id', p_user, 'placed_at', p_placed_at, 'items', p_items));
    RETURN v_id;
END $$;

-- Relay: nhận tối đa n sự kiện chưa gửi. SKIP LOCKED => nhiều relay song song không giẫm nhau, không chờ nhau.
-- Chỉ thấy sự kiện của transaction ĐÃ COMMIT, nên không bỏ sót như cách "id > last_id" (xem concurrency/).
CREATE FUNCTION claim_outbox(n int DEFAULT 100) RETURNS SETOF outbox LANGUAGE sql SET search_path = d09 AS $$
    UPDATE outbox o SET published_at = now()
    WHERE o.id IN (SELECT id FROM outbox WHERE published_at IS NULL ORDER BY id LIMIT n FOR UPDATE SKIP LOCKED)
    RETURNING o.* $$;

-- ===== Consumer / OLAP =====
-- Sổ ghi nhận đã xử lý: consumer idempotent (at-least-once delivery => có thể nhận trùng)
CREATE TABLE processed_events (
    consumer text   NOT NULL,
    event_id bigint NOT NULL,
    PRIMARY KEY (consumer, event_id)
);

-- Bảng sự thật (fact): mỗi dòng hàng bán ra. Tạo trong "kho phân tích" (ở đây cùng DB để tiện chạy)
CREATE TABLE sales_fact (
    sold_at     timestamptz NOT NULL,
    order_id    bigint NOT NULL,
    product_id  integer NOT NULL,
    category_id integer NOT NULL,
    qty         integer NOT NULL,
    amount      numeric(14,0) NOT NULL
);

-- Fact chỉ chèn thêm theo thời gian => sold_at tương quan với vị trí vật lý => BRIN nhỏ xíu thay cho B-tree
CREATE INDEX sales_fact_sold_brin ON sales_fact USING brin (sold_at) WITH (pages_per_range = 32);

-- Tổng hợp theo ngày x ngành hàng: dashboard đọc bảng này, không quét fact
CREATE TABLE daily_rollup (
    day         date NOT NULL,
    category_id integer NOT NULL,
    orders      bigint NOT NULL DEFAULT 0,
    revenue     numeric(16,0) NOT NULL DEFAULT 0,
    PRIMARY KEY (day, category_id)
);

-- Áp một sự kiện OrderPlaced vào fact + rollup: idempotent theo (consumer, event_id). Ngày tính theo thời điểm NGHIỆP VỤ (placed_at),
-- không theo lúc nhận => sự kiện đến trễ vẫn vào đúng ngày. Múi giờ báo cáo: giờ Việt Nam.
CREATE FUNCTION apply_order_placed(p_consumer text, p_event_id bigint, p_payload jsonb) RETURNS boolean
LANGUAGE plpgsql SET search_path = d09 AS $$
DECLARE v_n int;
BEGIN
    INSERT INTO processed_events (consumer, event_id) VALUES (p_consumer, p_event_id) ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    IF v_n = 0 THEN RETURN false; END IF;                                  -- đã xử lý: bỏ qua
    INSERT INTO sales_fact (sold_at, order_id, product_id, category_id, qty, amount)
    SELECT (p_payload->>'placed_at')::timestamptz, (p_payload->>'order_id')::bigint,
           (i->>'product_id')::int, (i->>'category_id')::int, (i->>'qty')::int, (i->>'amount')::numeric
    FROM jsonb_array_elements(p_payload->'items') i;
    INSERT INTO daily_rollup (day, category_id, orders, revenue)
    SELECT ((p_payload->>'placed_at')::timestamptz AT TIME ZONE 'Asia/Ho_Chi_Minh')::date, (i->>'category_id')::int,
           1, sum((i->>'amount')::numeric)
    FROM jsonb_array_elements(p_payload->'items') i
    GROUP BY 1, 2
    ON CONFLICT (day, category_id) DO UPDATE SET orders = daily_rollup.orders + EXCLUDED.orders, revenue = daily_rollup.revenue + EXCLUDED.revenue;
    RETURN true;
END $$;

-- Bảng cho thí nghiệm mất sự kiện khi poll theo id
CREATE TABLE demo_events (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, written_at timestamptz DEFAULT now(), published_at timestamptz);
CREATE TABLE demo_result (mode text PRIMARY KEY, seen bigint NOT NULL);
