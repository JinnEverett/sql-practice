WITH monthly AS (
  SELECT date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') AS m, sum(total_amount) AS revenue FROM orders
  WHERE created_at >= '2026-01-01 00:00+07' AND created_at < '2026-10-01 00:00+07' AND status NOT IN ('cancelled', 'refunded') GROUP BY 1)
SELECT to_char(m, 'YYYY-MM') AS thang, revenue,
       round(100.0 * (revenue - lag(revenue) OVER (ORDER BY m)) / lag(revenue) OVER (ORDER BY m), 1) AS mom_pct,
       round(100.0 * (revenue - lag(revenue, 12) OVER (ORDER BY m)) / lag(revenue, 12) OVER (ORDER BY m), 1) AS yoy_pct
FROM monthly ORDER BY m;
