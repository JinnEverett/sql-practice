CREATE INDEX ON orders (created_at DESC, id DESC);
-- query
SELECT id, created_at, total_amount FROM orders ORDER BY created_at DESC, id DESC OFFSET 900000 LIMIT 20;
