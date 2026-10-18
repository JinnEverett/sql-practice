-- db: shop_s
-- ordered
SELECT category_id, count(*) AS n_active, min(price) AS min_price, max(price) AS max_price
FROM products WHERE is_active GROUP BY category_id HAVING count(*) >= 8 ORDER BY category_id;
