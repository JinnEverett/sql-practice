-- db: shop_s
-- ordered
-- Giải thích: ROLLUP (root_name, category_name) cho 3 cấp: danh mục, tổng ngành, tổng chung. grouping(…) tính cấp.
--   pct_of_parent: so với dòng cha. Dòng danh mục so với tổng ngành, dòng ngành so với tổng chung. Lấy tổng cha bằng window
--   chạy TRÊN kết quả đã gom: max(revenue) FILTER (dòng cha) OVER (PARTITION BY …).
--   Sản phẩm có thể nằm thẳng ở danh mục cấp 2 hoặc cấp 3; "danh mục" ở đây là danh mục trực tiếp của sản phẩm.
-- Bẫy: tính % trên tổng chung cho mọi dòng; để dòng tổng NULL không nhãn.
WITH RECURSIVE tree AS (
  SELECT id, name AS root_name FROM categories WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, tree.root_name FROM categories c JOIN tree ON c.parent_id = tree.id
), r AS (
  SELECT tree.root_name, c.name AS category_name, grouping(tree.root_name, c.name) AS g,
         sum(oi.quantity * oi.unit_price) AS revenue
  FROM order_items oi
  JOIN orders o ON o.id = oi.order_id AND o.status = 'delivered'
  JOIN products p ON p.id = oi.product_id
  JOIN categories c ON c.id = p.category_id
  JOIN tree ON tree.id = p.category_id
  WHERE o.created_at >= '2026-09-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07'
  GROUP BY ROLLUP (tree.root_name, c.name)
)
SELECT coalesce(root_name, '(tất cả)') AS root_name,
       CASE g WHEN 0 THEN category_name WHEN 1 THEN '(tổng ngành)' ELSE '(tổng)' END AS category_name,
       CASE g WHEN 0 THEN 'danh mục' WHEN 1 THEN 'ngành' ELSE 'tổng' END AS cap,
       revenue,
       round(100.0 * revenue / CASE g
         WHEN 0 THEN max(revenue) FILTER (WHERE g = 1) OVER (PARTITION BY root_name)
         WHEN 1 THEN max(revenue) FILTER (WHERE g = 3) OVER ()
         ELSE revenue END, 1) AS pct_of_parent
FROM r
ORDER BY g = 3, root_name, g DESC, revenue DESC, category_name;
