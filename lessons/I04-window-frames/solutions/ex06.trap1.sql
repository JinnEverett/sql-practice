SELECT c.name AS category, p.id, p.price,
       round(avg(p.price) OVER (PARTITION BY p.category_id ORDER BY p.price DESC, p.id)) AS avg_price,
       round(p.price - avg(p.price) OVER (PARTITION BY p.category_id ORDER BY p.price DESC, p.id)) AS diff_from_avg,
       round(100.0 * p.price / max(p.price) OVER (PARTITION BY p.category_id), 1) AS pct_of_max
FROM products p JOIN categories c ON c.id = p.category_id
WHERE p.is_active AND c.name IN ('Trà', 'Cà phê') ORDER BY category, p.price DESC, p.id;
