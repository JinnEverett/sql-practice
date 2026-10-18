-- db: shop_s
-- mode: manual
-- Demo: bytes/dòng ở shop_s, dùng để ngoại suy sang shop_m / shop_l.
SELECT 'orders' AS t, pg_relation_size('orders') AS bytes, count(*) AS n, round(pg_relation_size('orders')::numeric / count(*), 1) AS bytes_per_row FROM orders
UNION ALL
SELECT 'events', pg_relation_size('events'), count(*), round(pg_relation_size('events')::numeric / count(*), 1) FROM events;
