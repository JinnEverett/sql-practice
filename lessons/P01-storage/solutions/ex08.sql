-- db: shop_s
-- ordered
-- expect-rows: 4
-- Giải thích: bytes/dòng thật: order_items 68, payments 79, orders 98, events 114 B. "Khoảng 100 B" đúng cho orders/events nhưng lệch 30%
--   cho bảng hẹp. Overhead mỗi dòng (tuple header 24–32 B + line pointer 4 B) cố định nên bảng càng hẹp càng chiếm tỉ lệ lớn
--   (order_items: 5 cột, 68 B, trong đó ≈ 32 B là overhead). Đây chỉ là heap; index, TOAST và fillfactor cộng thêm.
-- Bẫy: pg_total_relation_size; reltuples; quên ép kiểu numeric khi chia (chia nguyên).
SELECT 'events' AS table_name, count(*) AS n_rows, pg_relation_size('events') / current_setting('block_size')::int AS heap_pages,
       round(pg_relation_size('events')::numeric / count(*)) AS bytes_per_row FROM events
UNION ALL
SELECT 'order_items', count(*), pg_relation_size('order_items') / current_setting('block_size')::int,
       round(pg_relation_size('order_items')::numeric / count(*)) FROM order_items
UNION ALL
SELECT 'orders', count(*), pg_relation_size('orders') / current_setting('block_size')::int,
       round(pg_relation_size('orders')::numeric / count(*)) FROM orders
UNION ALL
SELECT 'payments', count(*), pg_relation_size('payments') / current_setting('block_size')::int,
       round(pg_relation_size('payments')::numeric / count(*)) FROM payments
ORDER BY table_name;
