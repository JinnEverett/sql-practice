WITH g AS (
  SELECT user_id, extract(epoch FROM created_at - lag(created_at) OVER (PARTITION BY user_id ORDER BY created_at, id)) / 86400 AS gap_days
  FROM orders WHERE status = 'delivered'),
per_user AS (SELECT user_id, count(*) AS n_orders, avg(gap_days) AS avg_gap, max(gap_days) AS last_gap FROM g GROUP BY user_id)
SELECT user_id, n_orders, round(avg_gap, 1) AS avg_gap_days, round(last_gap, 1) AS last_gap_days FROM per_user
WHERE n_orders >= 3 AND last_gap > 3 * avg_gap ORDER BY last_gap / avg_gap DESC, user_id;
