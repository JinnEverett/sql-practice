-- db: shop_s
-- ordered
-- Giải thích: self join CTE: mỗi tháng (cur) LEFT JOIN với tháng liền trước (prev) qua điều kiện prev.m = cur.m - 1 tháng.
--   CTE phải chứa cả tháng 12/2025 để tháng 1/2026 có số so sánh, nhưng kết quả chỉ in từ 2026.
--   (Cách gọn hơn là window function lag(), học ở I04.)
-- Bẫy: CTE chỉ lấy năm 2026 → tháng 1 không có prev (NULL); INNER JOIN làm mất tháng đầu.
WITH monthly AS (
  SELECT date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') AS m,
         sum(total_amount) AS revenue
  FROM orders
  WHERE created_at >= '2025-12-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
    AND status NOT IN ('cancelled', 'refunded')
  GROUP BY 1
)
SELECT to_char(cur.m, 'YYYY-MM') AS thang,
       cur.revenue,
       prev.revenue AS prev_revenue,
       round(100.0 * (cur.revenue - prev.revenue) / prev.revenue, 1) AS growth_pct
FROM monthly cur
LEFT JOIN monthly prev ON prev.m = cur.m - interval '1 month'
WHERE cur.m >= '2026-01-01'
ORDER BY cur.m;
