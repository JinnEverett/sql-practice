-- db: shop_s
-- ordered
-- Giải thích: gom số lượng bán theo (tháng VN, sản phẩm), rồi rank() trong từng tháng theo số lượng giảm dần.
--   Dùng rank (không phải row_number) để GIỮ mọi sản phẩm đồng hạng nhất.
-- Bẫy: row_number → mất sản phẩm đồng hạng; DISTINCT ON cũng chỉ giữ 1 dòng mỗi tháng.
WITH monthly AS (
  SELECT date_trunc('month', o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') AS m, oi.product_id, sum(oi.quantity) AS units
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.id
  WHERE o.status NOT IN ('cancelled', 'refunded')
    AND o.created_at >= '2026-01-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07'
  GROUP BY 1, 2
), ranked AS (
  SELECT m, product_id, units, rank() OVER (PARTITION BY m ORDER BY units DESC) AS rnk
  FROM monthly
)
SELECT to_char(r.m, 'YYYY-MM') AS thang, r.product_id, p.name, r.units
FROM ranked r
JOIN products p ON p.id = r.product_id
WHERE r.rnk = 1
ORDER BY thang, r.product_id;
