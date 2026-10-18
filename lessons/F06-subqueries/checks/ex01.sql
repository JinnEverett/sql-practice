-- db: shop_s
-- ordered
SELECT id, name, price FROM products
WHERE is_active AND price > (SELECT avg(price) FROM products WHERE is_active)
ORDER BY price DESC, id;
