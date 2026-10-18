-- sai: tính cả đơn cancelled
SELECT date_trunc('month', first_order AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS cohort_month, count(*) AS cohort_size
FROM (SELECT user_id, min(created_at) AS first_order FROM orders GROUP BY user_id) f
GROUP BY 1 ORDER BY 1;
