-- db: shop_s
-- ordered
-- Giải thích: neo = danh mục gốc 'Điện tử' (depth 0, path = tên). Đệ quy: nối categories con có parent_id = id của dòng vừa sinh,
--   depth + 1, path nối thêm ' > ' || tên con. Dừng tự nhiên khi không còn con.
-- Bẫy: neo bằng parent_id = 2 (mất chính 'Điện tử'); đệ quy JOIN ngược chiều (c.id = t.parent_id) là đi LÊN cây.
WITH RECURSIVE t AS (
  SELECT id, name, 0 AS depth, name AS path
  FROM categories
  WHERE name = 'Điện tử'
  UNION ALL
  SELECT c.id, c.name, t.depth + 1, t.path || ' > ' || c.name
  FROM categories c
  JOIN t ON c.parent_id = t.id
)
SELECT id, name, depth, path
FROM t
ORDER BY path;
