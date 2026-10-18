-- db: shop_s
-- mode: manual
-- Demo trong transaction: cùng một index, cách viết điều kiện quyết định có dùng được hay không.
BEGIN;
CREATE INDEX tmp_i05_demo ON orders (created_at);
EXPLAIN (COSTS OFF) SELECT count(*) FROM orders WHERE (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date = date '2026-09-15';
EXPLAIN (COSTS OFF) SELECT count(*) FROM orders WHERE created_at >= '2026-09-15 00:00+07' AND created_at < '2026-09-16 00:00+07';
ROLLBACK;
