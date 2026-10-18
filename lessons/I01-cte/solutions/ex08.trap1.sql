WITH first_orders AS (SELECT user_id, min(created_at) AS first_at FROM orders GROUP BY user_id),
new_customers AS (
  SELECT f.user_id, f.first_at,
         EXISTS (SELECT 1 FROM orders o WHERE o.user_id = f.user_id AND o.status <> 'cancelled'
                 AND o.created_at > f.first_at AND o.created_at <= f.first_at + interval '30 days') AS repeated
  FROM first_orders f WHERE f.first_at >= '2026-01-01 00:00+07' AND f.first_at < '2026-10-01 00:00+07')
SELECT to_char(date_trunc('month', first_at AT TIME ZONE 'Asia/Ho_Chi_Minh'), 'YYYY-MM') AS thang, count(*) AS n_new,
       count(*) FILTER (WHERE repeated) AS n_repeat_30d, round(100.0 * count(*) FILTER (WHERE repeated) / count(*), 1) AS pct_repeat
FROM new_customers GROUP BY 1 ORDER BY 1;
