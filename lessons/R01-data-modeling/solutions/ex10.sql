-- db: shop_s
-- mode: manual
-- Demo: xóa một user (chưa có đơn) khi FK orders.user_id và events.user_id KHÔNG có index, rồi so với khi có index.
-- Xem thời gian của "Trigger for constraint …" trong EXPLAIN ANALYZE. Mọi thứ nằm trong transaction và ROLLBACK.
BEGIN;
INSERT INTO users (email, full_name, country, created_at) VALUES ('tmp-fk@example.vn', 'Tmp', 'VN', now());
EXPLAIN (ANALYZE, COSTS OFF) DELETE FROM users WHERE email = 'tmp-fk@example.vn';
ROLLBACK;
BEGIN;
CREATE INDEX tmp_orders_user ON orders (user_id);
CREATE INDEX tmp_events_user ON events (user_id);
INSERT INTO users (email, full_name, country, created_at) VALUES ('tmp-fk@example.vn', 'Tmp', 'VN', now());
EXPLAIN (ANALYZE, COSTS OFF) DELETE FROM users WHERE email = 'tmp-fk@example.vn';
ROLLBACK;
