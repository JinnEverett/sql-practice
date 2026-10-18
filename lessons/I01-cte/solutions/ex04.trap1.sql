WITH monthly AS (
  SELECT date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') AS m, sum(total_amount) AS revenue
  FROM orders WHERE created_at >= '2026-01-01 00:00+07' AND created_at < '2026-10-01 00:00+07' AND status NOT IN ('cancelled', 'refunded')
  GROUP BY 1)
SELECT to_char(cur.m, 'YYYY-MM') AS thang, cur.revenue, prev.revenue AS prev_revenue,
       round(100.0 * (cur.revenue - prev.revenue) / prev.revenue, 1) AS growth_pct
FROM monthly cur LEFT JOIN monthly prev ON prev.m = cur.m - interval '1 month' ORDER BY cur.m;
