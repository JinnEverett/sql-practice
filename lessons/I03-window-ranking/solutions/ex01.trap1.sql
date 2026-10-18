SELECT category_id, id, name, price, rn
FROM (SELECT category_id, id, name, price, row_number() OVER (PARTITION BY category_id ORDER BY price DESC, id) AS rn FROM products) t
WHERE rn <= 3 ORDER BY category_id, rn;
