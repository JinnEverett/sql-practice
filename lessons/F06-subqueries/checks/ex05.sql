-- db: shop_s
-- ordered
SELECT u.id, u.full_name, u.created_at FROM users u
WHERE NOT EXISTS (SELECT 1 FROM events e WHERE e.user_id = u.id)
ORDER BY u.id;
