WITH RECURSIVE up AS (
  SELECT p.id AS product_id, c.parent_id, c.name::text AS breadcrumb FROM products p JOIN categories c ON c.id = p.category_id WHERE p.id <= 5
  UNION ALL
  SELECT up.product_id, c.parent_id, up.breadcrumb || ' > ' || c.name FROM up JOIN categories c ON c.id = up.parent_id)
SELECT product_id, breadcrumb FROM up WHERE parent_id IS NULL ORDER BY product_id;
