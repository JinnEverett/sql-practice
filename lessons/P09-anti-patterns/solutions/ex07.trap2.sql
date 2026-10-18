-- query
SELECT u.id AS user_id, o.id AS order_id, o.created_at
FROM generate_series(1, 50) AS u(id)
CROSS JOIN LATERAL (SELECT id, created_at FROM orders WHERE user_id = u.id ORDER BY created_at DESC, id DESC LIMIT 1) o;
