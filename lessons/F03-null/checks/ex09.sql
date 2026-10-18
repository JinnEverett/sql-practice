-- db: shop_s
-- ordered
SELECT id, coalesce(full_name, 'Quý khách') AS greeting_name, phone FROM users
WHERE country = 'VN' AND deleted_at IS NULL AND phone IS NOT NULL AND birth_date IS NULL
ORDER BY id;
