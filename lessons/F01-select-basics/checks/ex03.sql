-- db: shop_s
-- ordered
SELECT DISTINCT brand FROM products WHERE category_id IN (9, 10, 11, 12) ORDER BY brand;
