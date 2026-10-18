WITH RECURSIVE tree AS (
  SELECT id, name AS root_name FROM categories WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, tree.root_name FROM categories c JOIN tree ON c.parent_id = tree.id)
SELECT tree.root_name,
       sum(oi.quantity * oi.unit_price) FILTER (WHERE extract(quarter FROM o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') = 1) AS q1,
       sum(oi.quantity * oi.unit_price) FILTER (WHERE extract(quarter FROM o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') = 2) AS q2,
       sum(oi.quantity * oi.unit_price) FILTER (WHERE extract(quarter FROM o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') = 3) AS q3
FROM order_items oi JOIN orders o ON o.id = oi.order_id AND o.status = 'delivered'
JOIN products p ON p.id = oi.product_id JOIN tree ON tree.id = p.category_id
WHERE o.created_at >= '2026-01-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07'
GROUP BY tree.root_name ORDER BY tree.root_name;
