-- db: shop_s
-- ordered
SELECT id, full_name, email, created_at FROM users
WHERE country = 'VN' AND created_at >= '2025-01-01' AND created_at < '2026-01-01'
ORDER BY created_at, id;
