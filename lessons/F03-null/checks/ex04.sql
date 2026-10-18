-- db: shop_s
-- ordered
SELECT id, full_name, birth_date FROM users
ORDER BY birth_date DESC NULLS LAST, id LIMIT 10;
