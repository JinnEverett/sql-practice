-- sai: chỉ đếm sản phẩm gắn trực tiếp vào danh mục gốc
SELECT r.id AS root_id, r.name AS root_name, 1 AS n_categories, count(p.id) AS n_products
FROM r06.cat r LEFT JOIN r06.prod p ON p.category_id = r.id
WHERE r.parent_id IS NULL GROUP BY r.id, r.name ORDER BY r.id;
