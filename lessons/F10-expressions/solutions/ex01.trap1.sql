SELECT CASE WHEN price < 100000 THEN 'bình dân' WHEN price < 1000000 THEN 'trung cấp' WHEN price < 10000000 THEN 'cao cấp' ELSE 'xa xỉ' END AS segment,
       count(*) AS n_products
FROM products WHERE is_active GROUP BY 1 ORDER BY segment;
