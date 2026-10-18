CREATE INDEX ON orders (((created_at AT TIME ZONE 'UTC')::date));
-- query
SELECT count(*) FROM orders WHERE (created_at AT TIME ZONE 'UTC')::date = DATE '2026-09-11';
