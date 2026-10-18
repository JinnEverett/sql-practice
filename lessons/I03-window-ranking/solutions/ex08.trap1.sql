WITH spent AS (
  SELECT user_id, sum(total_amount) AS total_spent, ntile(100) OVER (ORDER BY sum(total_amount), user_id) AS pct_bucket
  FROM orders WHERE status = 'delivered' GROUP BY user_id)
SELECT nhom, count(*) AS n_users, sum(total_spent) AS revenue,
       round(100.0 * sum(total_spent) / sum(sum(total_spent)) OVER (), 1) AS pct_revenue
FROM (SELECT CASE WHEN pct_bucket = 1 THEN 'top 1%' WHEN pct_bucket <= 10 THEN 'top 2-10%' ELSE 'còn lại' END AS nhom, total_spent, pct_bucket FROM spent) t
GROUP BY nhom ORDER BY min(pct_bucket);
