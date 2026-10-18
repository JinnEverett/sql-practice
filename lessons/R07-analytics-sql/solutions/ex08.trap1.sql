-- sai: mẫu số là số khách mua lại → tỉ lệ luôn 100%
WITH ranked AS (SELECT user_id, (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day, row_number() OVER (PARTITION BY user_id ORDER BY created_at, id) AS rn FROM orders WHERE status <> 'cancelled'),
per_user AS (SELECT user_id, max(day) FILTER (WHERE rn = 1) AS first_day, max(day) FILTER (WHERE rn = 2) AS second_day FROM ranked WHERE rn <= 2 GROUP BY user_id)
SELECT count(*) FILTER (WHERE second_day IS NOT NULL) AS n_buyers, count(second_day) AS n_repeat,
       round(100.0 * count(second_day) / count(second_day), 1) AS repeat_rate_pct,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY second_day - first_day)::numeric, 1) AS median_days_to_second
FROM per_user;
