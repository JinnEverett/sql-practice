SELECT c.id AS category_id, c.name AS category, p.id AS product_id, p.name AS product_name, p.price
FROM categories c CROSS JOIN LATERAL (SELECT id, name, price FROM products WHERE category_id = c.id AND is_active ORDER BY price DESC, id LIMIT 1) p
ORDER BY c.id;
