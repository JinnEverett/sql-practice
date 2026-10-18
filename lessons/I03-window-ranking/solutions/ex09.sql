-- db: shop_s
-- ordered
-- Giải thích: tính doanh thu sản phẩm theo tháng cho CẢ tháng 8 và 9, xếp hạng trong từng tháng (rank theo doanh thu giảm dần),
--   rồi LEFT JOIN bảng hạng tháng 9 (top 10) với bảng hạng tháng 8 → sản phẩm không bán ở tháng 8 có rank_aug NULL.
--   change = rank_aug − rank_sep (dương = tăng hạng). Xếp hạng tháng 8 phải tính trên MỌI sản phẩm tháng 8, không chỉ top 10.
-- Bẫy: xếp hạng tháng 8 chỉ trong nhóm 10 sản phẩm top tháng 9; INNER JOIN làm mất sản phẩm mới.
WITH rev AS (
  SELECT date_trunc('month', o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') AS m, oi.product_id,
         sum(oi.quantity * oi.unit_price) AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.id
  WHERE o.status NOT IN ('cancelled', 'refunded')
    AND o.created_at >= '2026-08-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07'
  GROUP BY 1, 2
), ranked AS (
  SELECT m, product_id, revenue, rank() OVER (PARTITION BY m ORDER BY revenue DESC) AS rnk
  FROM rev
)
SELECT s.product_id, p.name, s.rnk AS rank_sep, a.rnk AS rank_aug, a.rnk - s.rnk AS change
FROM ranked s
JOIN products p ON p.id = s.product_id
LEFT JOIN ranked a ON a.product_id = s.product_id AND a.m = '2026-08-01'
WHERE s.m = '2026-09-01' AND s.rnk <= 10
ORDER BY rank_sep, s.product_id;
