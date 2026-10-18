CREATE INDEX ON orders (created_at);
-- query
SELECT count(*) FROM orders WHERE created_at::date = DATE '2026-09-11';
