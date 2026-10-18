-- db: shop_s
-- mode: manual
-- Demo: OFFSET sâu so với keyset, có và không có index (trong transaction, ROLLBACK). Với shop_m thay 9000 bằng 900000.
BEGIN;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT id, created_at, total_amount FROM orders ORDER BY created_at DESC, id DESC LIMIT 20 OFFSET 9000;
CREATE INDEX tmp_r02 ON orders (created_at DESC, id DESC);
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT id, created_at, total_amount FROM orders ORDER BY created_at DESC, id DESC LIMIT 20 OFFSET 9000;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT id, created_at, total_amount FROM orders
WHERE (created_at, id) < (SELECT created_at, id FROM orders ORDER BY created_at DESC, id DESC OFFSET 9000 LIMIT 1)
ORDER BY created_at DESC, id DESC LIMIT 20;
ROLLBACK;
