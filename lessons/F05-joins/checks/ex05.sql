-- db: shop_s
-- ordered
SELECT c.id, c.name, coalesce(p.name, '(gốc)') AS parent_name
FROM categories c LEFT JOIN categories p ON p.id = c.parent_id
ORDER BY c.id;
