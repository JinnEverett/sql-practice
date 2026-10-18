-- db: shop_s
-- ordered
-- Giải thích: tính doanh thu MỌI tháng (từ 2025-01) trước, rồi lag(revenue, 1) (tháng trước) và lag(revenue, 12) (cùng kỳ năm trước),
--   sau đó mới lọc 2026 ở tầng ngoài. lag(x, 12) chỉ đúng là "cùng tháng năm trước" khi không thiếu tháng nào ở giữa.
-- Bẫy: lọc 2026 trước khi lag → yoy toàn NULL, mom tháng 1 NULL.
WITH monthly AS (
  SELECT date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') AS m, sum(total_amount) AS revenue
  FROM orders
  WHERE created_at >= '2025-01-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
    AND status NOT IN ('cancelled', 'refunded')
  GROUP BY 1
), cmp AS (
  SELECT m, revenue, lag(revenue, 1) OVER (ORDER BY m) AS prev_m, lag(revenue, 12) OVER (ORDER BY m) AS prev_y
  FROM monthly
)
SELECT to_char(m, 'YYYY-MM') AS thang, revenue,
       round(100.0 * (revenue - prev_m) / prev_m, 1) AS mom_pct,
       round(100.0 * (revenue - prev_y) / prev_y, 1) AS yoy_pct
FROM cmp
WHERE m >= '2026-01-01'
ORDER BY m;
