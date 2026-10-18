-- sai: neo là chính nút 2 → có thêm dòng gốc và depth lệch một bậc
WITH RECURSIVE sub AS (
  SELECT id, name, 0 AS depth FROM categories WHERE id = 2
  UNION ALL
  SELECT c.id, c.name, s.depth + 1 FROM categories c JOIN sub s ON c.parent_id = s.id)
SELECT id, name, depth FROM sub ORDER BY depth, id;
