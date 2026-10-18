-- db: shop_s
-- ordered
SELECT p.id, p.name, p.category_id, p.price,
       (SELECT round(avg(p2.price), 0) FROM products p2
        WHERE p2.category_id = p.category_id AND p2.is_active) AS category_avg
FROM products p
WHERE p.is_active
  AND p.price > (SELECT avg(p2.price) FROM products p2
                 WHERE p2.category_id = p.category_id AND p2.is_active)
ORDER BY p.category_id, p.price DESC, p.id;
