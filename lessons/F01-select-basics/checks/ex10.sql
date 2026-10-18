-- db: shop_s
-- ordered
SELECT id, full_name, email, created_at FROM users
WHERE country = 'VN' AND deleted_at IS NULL
ORDER BY created_at, id LIMIT 10;
