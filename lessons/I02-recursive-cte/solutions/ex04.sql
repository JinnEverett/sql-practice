-- db: shop_s
-- ordered
-- Giải thích: CTE đệ quy mang theo root_id từ neo (các danh mục gốc) xuống mọi con cháu → bảng ánh xạ danh mục → gốc.
--   Rồi doanh thu dòng hàng (đơn delivered) JOIN products → ánh xạ → gom theo gốc. Sản phẩm có thể nằm ở tầng 2 hoặc 3:
--   ánh xạ đệ quy xử lý mọi độ sâu, còn JOIN categories cố định 1 tầng cha thì không.
-- Bẫy: JOIN categories 1 lần để lấy parent → sai với sản phẩm tầng 3 (ra tầng 2 thay vì gốc) và tầng 2 thì đúng → kết quả lẫn lộn.
WITH RECURSIVE tree AS (
  SELECT id, id AS root_id, name AS root_name
  FROM categories
  WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, tree.root_id, tree.root_name
  FROM categories c
  JOIN tree ON c.parent_id = tree.id
)
SELECT tree.root_name, sum(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN orders o   ON o.id = oi.order_id AND o.status = 'delivered'
JOIN products p ON p.id = oi.product_id
JOIN tree       ON tree.id = p.category_id
GROUP BY tree.root_name
ORDER BY revenue DESC;
