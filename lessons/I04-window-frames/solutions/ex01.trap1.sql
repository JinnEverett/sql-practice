WITH daily AS (
  SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS ngay, sum(total_amount) AS revenue FROM orders
  WHERE created_at >= '2026-09-01 00:00+07' AND created_at < '2026-10-01 00:00+07' AND status NOT IN ('cancelled', 'refunded') GROUP BY 1)
SELECT ngay, revenue, sum(revenue) OVER () AS cum_revenue FROM daily ORDER BY ngay;
