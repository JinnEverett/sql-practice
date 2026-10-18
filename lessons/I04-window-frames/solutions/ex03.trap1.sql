WITH daily AS (
  SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS ngay, sum(total_amount) AS revenue FROM orders
  WHERE created_at >= '2026-09-01 00:00+07' AND created_at < '2026-10-01 00:00+07' AND status NOT IN ('cancelled', 'refunded') GROUP BY 1)
SELECT ngay, revenue, round(avg(revenue) OVER (ORDER BY ngay ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) AS ma7 FROM daily ORDER BY ngay;
