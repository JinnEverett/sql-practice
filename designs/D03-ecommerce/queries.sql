-- D03 · queries.sql — seed + access pattern + ASSERT. Chạy sau schema.sql.
SET search_path = d03;
SET client_min_messages = warning;

-- §0 Seed: 20k user, 2k sản phẩm, 300k đơn lịch sử (INSERT hàng loạt, bỏ qua place_order), ~750k order_items
INSERT INTO users (email) SELECT 'u' || g || '@example.com' FROM generate_series(1, 20000) g;
INSERT INTO products (sku, name, price)
SELECT 'SKU' || g, 'Sản phẩm ' || g, (50 + (g * 37) % 5000) * 1000 FROM generate_series(1, 2000) g;
INSERT INTO inventory (product_id, on_hand) SELECT id, 1000 FROM products;
INSERT INTO orders (user_id, idempotency_key, status, total_amount, created_at)
SELECT 1 + (g * 7) % 20000, 'seed-' || g,
       CASE WHEN g % 12 = 0 THEN 'cancelled' WHEN g % 40 = 0 THEN 'refunded' ELSE 'delivered' END,
       100000, timestamptz '2026-01-01' + g * interval '90 seconds'
FROM generate_series(1, 300000) g;
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price)
SELECT o.id, l, 1 + (o.id * l * 13) % 2000, 1 + (o.id % 3), 100000
FROM orders o, generate_series(1, 2) l;
ANALYZE;

-- §1 A1 · đặt đơn: giữ chỗ, idempotent, hết hàng thì rollback cả đơn
DO $$
DECLARE o1 bigint; o2 bigint; r int; ok boolean := false;
BEGIN
    UPDATE inventory SET on_hand = 5, reserved = 0 WHERE product_id = 1;
    o1 := place_order(1, 'k-1', '[{"product_id":1,"qty":3}]');
    o2 := place_order(1, 'k-1', '[{"product_id":1,"qty":3}]');            -- gửi lại cùng key
    ASSERT o1 = o2, 'idempotency: phải trả cùng đơn';
    SELECT reserved INTO r FROM inventory WHERE product_id = 1;
    ASSERT r = 3, 'retry không được giữ chỗ lần 2';
    BEGIN
        PERFORM place_order(2, 'k-2', '[{"product_id":1,"qty":3}]');      -- chỉ còn 2
    EXCEPTION WHEN SQLSTATE 'OOS01' THEN ok := true; END;
    ASSERT ok, 'phải báo hết hàng';
    ASSERT NOT EXISTS (SELECT 1 FROM orders WHERE user_id = 2 AND idempotency_key = 'k-2'), 'đơn hết hàng phải rollback';
    SELECT reserved INTO r FROM inventory WHERE product_id = 1;
    ASSERT r = 3, 'giữ chỗ không đổi khi thất bại';
END $$;

-- §2 State machine: không nhảy cóc, không quay lui
DO $$
DECLARE o bigint; bad int := 0;
BEGIN
    SELECT id INTO o FROM orders WHERE user_id = 1 AND idempotency_key = 'k-1';
    BEGIN UPDATE orders SET status = 'delivered' WHERE id = o; EXCEPTION WHEN check_violation THEN bad := bad + 1; END;   -- pending -> delivered
    UPDATE orders SET status = 'paid' WHERE id = o;                                                                          -- hợp lệ (bỏ qua kho, test riêng ở §3)
    BEGIN UPDATE orders SET status = 'pending' WHERE id = o; EXCEPTION WHEN check_violation THEN bad := bad + 1; END;      -- paid -> pending
    ASSERT bad = 2, 'state machine để lọt chuyển trạng thái sai';
    ASSERT (SELECT count(*) FROM order_status_log WHERE order_id = o) = 1, 'log chỉ ghi chuyển hợp lệ';
END $$;
-- (đơn k-1 đã sang paid không qua confirm_payment; dọn lại cho các bước sau)
UPDATE inventory SET on_hand = 5, reserved = 0 WHERE product_id = 1;

-- §3 A2 · thanh toán: webhook gửi 3 lần, sai số tiền bị từ chối, trừ kho đúng 1 lần
DO $$
DECLARE o bigint; r1 boolean; r2 boolean; r3 boolean; oh int; rs int; ok boolean := false;
BEGIN
    UPDATE inventory SET on_hand = 5, reserved = 0 WHERE product_id = 2;
    o := place_order(3, 'k-3', '[{"product_id":2,"qty":2}]');
    BEGIN PERFORM confirm_payment(o, 'wrong', 1); EXCEPTION WHEN check_violation THEN ok := true; END;
    ASSERT ok, 'sai số tiền phải bị từ chối';
    r1 := confirm_payment(o, 'ref-3', (SELECT total_amount FROM orders WHERE id = o));
    r2 := confirm_payment(o, 'ref-3', (SELECT total_amount FROM orders WHERE id = o));
    r3 := confirm_payment(o, 'ref-3', (SELECT total_amount FROM orders WHERE id = o));
    ASSERT r1 AND NOT r2 AND NOT r3, 'webhook lặp phải bị bỏ qua';
    SELECT on_hand, reserved INTO oh, rs FROM inventory WHERE product_id = 2;
    ASSERT oh = 3 AND rs = 0, format('kho sau thanh toán sai: on_hand=%s reserved=%s', oh, rs);
    ASSERT (SELECT count(*) FROM payments WHERE order_id = o) = 1, 'chỉ 1 payment';
END $$;

-- §4 A3 · hết hạn đơn pending: hủy + trả giữ chỗ (partial index orders_pending_idx)
DO $$
DECLARE o bigint; rs int;
BEGIN
    UPDATE inventory SET on_hand = 5, reserved = 0 WHERE product_id = 3;
    o := place_order(4, 'k-4', '[{"product_id":3,"qty":4}]');
    ASSERT cancel_pending(o), 'hủy được đơn pending';
    ASSERT NOT cancel_pending(o), 'hủy lần hai là no-op';
    SELECT reserved INTO rs FROM inventory WHERE product_id = 3;
    ASSERT rs = 0, 'phải trả giữ chỗ';
END $$;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT id FROM orders WHERE status = 'pending' AND created_at < now() - interval '15 minutes' ORDER BY created_at LIMIT 100;

-- §5 A4 · lịch sử đơn của user + dòng hàng (1 user, 20 đơn mới nhất)
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT o.id, o.status, o.total_amount, o.created_at FROM orders o WHERE o.user_id = 77 ORDER BY o.created_at DESC LIMIT 20;

-- §6 Lưới an toàn: ngay cả code sai (UPDATE trực tiếp) cũng không tạo âm kho
DO $$
BEGIN
    BEGIN UPDATE inventory SET reserved = on_hand + 1 WHERE product_id = 5; ASSERT false, 'phải bị CHECK chặn';
    EXCEPTION WHEN check_violation THEN NULL; END;
END $$;

-- §7 Đối soát: reserved của mỗi sản phẩm = tổng quantity của đơn pending (chỉ xét các sản phẩm đã đụng ở trên)
SELECT i.product_id, i.reserved, COALESCE(p.q, 0) AS pending_qty
FROM inventory i
LEFT JOIN (SELECT oi.product_id, sum(oi.quantity) q FROM order_items oi JOIN orders o ON o.id = oi.order_id
           WHERE o.status = 'pending' GROUP BY 1) p USING (product_id)
WHERE i.product_id IN (1, 2, 3) AND i.reserved IS DISTINCT FROM COALESCE(p.q, 0);

-- §8 Kích thước thực đo
SELECT relname, reltuples::bigint AS n, pg_size_pretty(pg_total_relation_size(oid)) AS total
FROM pg_class WHERE relnamespace = 'd03'::regnamespace AND relkind = 'r' AND relname IN ('orders','order_items','inventory','products','users')
ORDER BY pg_total_relation_size(oid) DESC;
