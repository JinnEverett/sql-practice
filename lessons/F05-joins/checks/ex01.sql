-- db: shop_s
-- ordered
SELECT o.id AS order_id, u.full_name, o.status, o.total_amount
FROM orders o JOIN users u ON u.id = o.user_id
WHERE o.id BETWEEN 5001 AND 5010
ORDER BY o.id;
