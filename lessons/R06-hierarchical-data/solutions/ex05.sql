-- db: lab
-- reset
-- ordered
-- expect-rows: 8
-- Giải thích: với closure table (có cặp tự thân), "mọi thứ nằm dưới danh mục gốc g" là JOIN phẳng: closure.ancestor = g → closure.descendant → sản phẩm.
--   Không đệ quy, một lần quét. count(DISTINCT) không cần vì mỗi (ancestor, descendant) duy nhất và mỗi sản phẩm thuộc đúng một danh mục.
--   LEFT JOIN để gốc không có sản phẩm nào vẫn hiện (đếm 0). Ở dữ liệu này mọi gốc đều có sản phẩm trong cây con.
-- Bẫy: JOIN thẳng products.category_id = root.id chỉ đếm sản phẩm gắn TRỰC TIẾP vào gốc (luôn 0 ở đây); loại cặp depth = 0 làm mất sản phẩm gắn thẳng vào danh mục.
SELECT r.id AS root_id, r.name AS root_name,
       count(DISTINCT k.descendant) AS n_categories,
       count(p.id) AS n_products
FROM r06.cat r
JOIN r06.cat_closure_ready k ON k.ancestor = r.id
LEFT JOIN r06.prod p ON p.category_id = k.descendant
WHERE r.parent_id IS NULL
GROUP BY r.id, r.name
ORDER BY r.id;
