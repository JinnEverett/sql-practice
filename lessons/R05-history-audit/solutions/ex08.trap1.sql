-- sai: điều kiện thời gian trong WHERE → total_orders chỉ đếm đơn sau khi xóa
SELECT u.id AS user_id, u.deleted_at, count(o.id) AS orders_after_deletion, sum(o.total_amount) AS amount_after_deletion, count(o.id) AS total_orders
FROM users u JOIN orders o ON o.user_id = u.id
WHERE u.deleted_at IS NOT NULL AND o.created_at >= u.deleted_at
GROUP BY u.id, u.deleted_at
ORDER BY orders_after_deletion DESC, user_id;
