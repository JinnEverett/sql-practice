-- db: shop_s
-- ordered
SELECT c.id, c.name,
       (SELECT count(*) FROM products p WHERE p.category_id = c.id AND p.is_active) AS n_active_products
FROM categories c
WHERE NOT EXISTS (SELECT 1 FROM categories k WHERE k.parent_id = c.id)
ORDER BY n_active_products DESC, c.id;
