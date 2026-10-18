-- db: shop_s
-- reset
-- ordered
-- Giải thích: crosstab(source_sql, category_sql) của extension tablefunc: source trả 3 cột (hàng, cột, giá trị) đã ORDER BY hàng;
--   category_sql liệt kê các giá trị cột theo đúng thứ tự cột đầu ra. Phải khai báo kiểu kết quả ở AS ct(…).
--   Dạng 2 tham số an toàn khi thiếu ô (ngành không bán quý nào → NULL đúng cột). Cách FILTER (alt1) đơn giản hơn khi số cột cố định.
-- Bẫy: crosstab 1 tham số khi có ô thiếu → giá trị bị dồn sang trái vào sai cột.
SELECT *
FROM crosstab(
  $$WITH RECURSIVE tree AS (
      SELECT id, name AS root_name FROM categories WHERE parent_id IS NULL
      UNION ALL
      SELECT c.id, tree.root_name FROM categories c JOIN tree ON c.parent_id = tree.id)
    SELECT tree.root_name,
           extract(quarter FROM o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::int,
           sum(oi.quantity * oi.unit_price)
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id AND o.status = 'delivered'
    JOIN products p ON p.id = oi.product_id
    JOIN tree ON tree.id = p.category_id
    WHERE o.created_at >= '2026-01-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07'
    GROUP BY 1, 2
    ORDER BY 1, 2$$,
  $$VALUES (1), (2), (3)$$
) AS ct(root_name text, q1 numeric, q2 numeric, q3 numeric)
ORDER BY root_name;
