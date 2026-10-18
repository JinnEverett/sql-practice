-- query
SELECT DISTINCT ON (user_id) user_id, id AS order_id, created_at FROM orders WHERE user_id <= 50 ORDER BY user_id, created_at DESC, id DESC;
