-- sai: coi unit_price là thuộc tính của sản phẩm → báo thêm BUT (5000/5500) và VO (12000/12500)
SELECT 'customer' AS entity, customer_id::text AS key, 'customer_city' AS attribute, count(DISTINCT customer_city) AS n_values
FROM r01.flat_sales GROUP BY customer_id HAVING count(DISTINCT customer_city) > 1
UNION ALL
SELECT 'product', sku, 'product_name', count(DISTINCT product_name)
FROM r01.flat_sales GROUP BY sku HAVING count(DISTINCT product_name) > 1
UNION ALL
SELECT 'product', sku, 'unit_price', count(DISTINCT unit_price)
FROM r01.flat_sales GROUP BY sku HAVING count(DISTINCT unit_price) > 1
ORDER BY entity, key, attribute;
