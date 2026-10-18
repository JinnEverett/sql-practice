-- db: shop_s
-- mode: manual
-- Demo: với index (user_id, created_at DESC, id DESC), LATERAL ra Index Only Scan trong Limit (loops = số khách).
BEGIN;
CREATE INDEX tmp_lat_demo ON orders (user_id, created_at DESC, id DESC);
EXPLAIN (COSTS OFF) SELECT u.id, o.id FROM users u CROSS JOIN LATERAL
  (SELECT id FROM orders WHERE user_id = u.id ORDER BY created_at DESC, id DESC LIMIT 2) o WHERE u.id <= 100;
ROLLBACK;
