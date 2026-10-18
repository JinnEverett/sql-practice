-- db: shop_s
-- ordered
SELECT u.id, u.full_name, u.created_at
FROM users u LEFT JOIN orders o ON o.user_id = u.id
WHERE o.id IS NULL
ORDER BY u.id;
