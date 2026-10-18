WITH numbered AS (
  SELECT created_at, total_amount, row_number() OVER (PARTITION BY user_id ORDER BY created_at, id) AS nth
  FROM orders WHERE status <> 'cancelled' AND created_at >= '2026-01-01 00:00+07' AND created_at < '2026-10-01 00:00+07')
SELECT to_char(date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh'), 'YYYY-MM') AS thang,
       sum(total_amount) FILTER (WHERE nth = 1) AS first_order_revenue, sum(total_amount) FILTER (WHERE nth > 1) AS repeat_revenue
FROM numbered GROUP BY 1 ORDER BY 1;
