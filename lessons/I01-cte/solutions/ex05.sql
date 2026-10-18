-- db: shop_s
-- ordered
-- Giải thích: gom từng loại event THEO SẢN PHẨM trong CTE riêng, rồi mới JOIN (mỗi bên đã còn 1 dòng/sản phẩm → không fan-out).
--   properties->>'product_id' lấy giá trị text từ jsonb (I07 học kỹ), ép ::bigint để nối với products.id.
--   LEFT JOIN carts + coalesce: sản phẩm được xem mà chưa ai thêm giỏ vẫn hiện với 0.
-- Bẫy: JOIN thẳng hai tập event rồi count → nhân dòng (n_views × n_carts); INNER JOIN carts làm mất sản phẩm 0 lần thêm giỏ.
WITH views AS (
  SELECT (properties->>'product_id')::bigint AS product_id, count(*) AS n_views
  FROM events WHERE event_type = 'product_view'
  GROUP BY 1
), carts AS (
  SELECT (properties->>'product_id')::bigint AS product_id, count(*) AS n_carts
  FROM events WHERE event_type = 'add_to_cart'
  GROUP BY 1
)
SELECT v.product_id, p.name, v.n_views,
       coalesce(c.n_carts, 0) AS n_carts,
       round(100.0 * coalesce(c.n_carts, 0) / v.n_views, 1) AS cart_rate
FROM views v
JOIN products p ON p.id = v.product_id
LEFT JOIN carts c ON c.product_id = v.product_id
WHERE v.n_views >= 50
ORDER BY cart_rate, v.product_id
LIMIT 10;
