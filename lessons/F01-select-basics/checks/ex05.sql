-- db: shop_s
-- ordered
SELECT id, name, price, round(price / 25000, 2) AS price_usd FROM products
WHERE is_active AND category_id IN (9, 10) AND round(price / 25000, 2) > 20
ORDER BY price_usd DESC, id;
