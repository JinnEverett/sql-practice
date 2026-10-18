-- db: shop_s
-- ordered
SELECT u.id, u.full_name, count(o.id) AS n_orders
FROM users u LEFT JOIN orders o ON o.user_id = u.id
WHERE u.country = 'JP'
GROUP BY u.id, u.full_name
ORDER BY n_orders DESC, u.id;
