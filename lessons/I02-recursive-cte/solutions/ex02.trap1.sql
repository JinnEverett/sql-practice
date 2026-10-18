WITH RECURSIVE t AS (
  SELECT id, name, 1 AS depth, name AS path FROM categories WHERE parent_id = 2
  UNION ALL
  SELECT c.id, c.name, t.depth + 1, t.path || ' > ' || c.name FROM categories c JOIN t ON c.parent_id = t.id)
SELECT id, name, depth, path FROM t ORDER BY path;
