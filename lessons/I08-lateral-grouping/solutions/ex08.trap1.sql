WITH RECURSIVE tree AS (
  SELECT id, name AS root_name FROM categories WHERE parent_id IS NULL
  UNION ALL SELECT c.id, tree.root_name FROM categories c JOIN tree ON c.parent_id = tree.id),
r AS (
  SELECT tree.root_name, c.name AS category_name, grouping(tree.root_name, c.name) AS g, sum(oi.quantity * oi.unit_price) AS revenue
  FROM order_items oi JOIN orders o ON o.id = oi.order_id AND o.status = 'delivered'
  JOIN products p ON p.id = oi.product_id JOIN categories c ON c.id = p.category_id JOIN tree ON tree.id = p.category_id
  WHERE o.created_at >= '2026-09-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07'
  GROUP BY ROLLUP (tree.root_name, c.name))
SELECT coalesce(root_name, '(tất cả)') AS root_name,
       CASE g WHEN 0 THEN category_name WHEN 1 THEN '(tổng ngành)' ELSE '(tổng)' END AS category_name,
       CASE g WHEN 0 THEN 'danh mục' WHEN 1 THEN 'ngành' ELSE 'tổng' END AS cap, revenue,
       round(100.0 * revenue / max(revenue) FILTER (WHERE g = 3) OVER (), 1) AS pct_of_parent
FROM r ORDER BY g = 3, root_name, g DESC, revenue DESC, category_name;
