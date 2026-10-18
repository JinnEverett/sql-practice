-- db: shop_s
-- ordered
SELECT id, name, price FROM products
WHERE name ILIKE '%sony%' AND is_active AND price < 5000000
ORDER BY price, id;
