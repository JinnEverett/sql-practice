-- sai: breadcrumb bắt đầu bằng ' > ' thừa ở đầu (nối với chuỗi rỗng ở gốc)
WITH RECURSIVE t AS (
  SELECT id, ' > ' || name AS breadcrumb, 0 AS depth FROM categories WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, t.breadcrumb || ' > ' || c.name, t.depth + 1 FROM categories c JOIN t ON c.parent_id = t.id)
SELECT id, breadcrumb, depth FROM t ORDER BY id;
