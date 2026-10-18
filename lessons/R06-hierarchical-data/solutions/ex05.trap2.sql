-- sai: bỏ cặp depth = 0 → mất sản phẩm gắn thẳng vào danh mục và chính danh mục gốc
SELECT r.id AS root_id, r.name AS root_name, count(DISTINCT k.descendant) AS n_categories, count(p.id) AS n_products
FROM r06.cat r JOIN r06.cat_closure_ready k ON k.ancestor = r.id AND k.depth > 0
LEFT JOIN r06.prod p ON p.category_id = k.descendant
WHERE r.parent_id IS NULL GROUP BY r.id, r.name ORDER BY r.id;
