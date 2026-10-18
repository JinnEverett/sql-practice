-- sai: cắt tháng theo UTC
SELECT date_trunc('month', first_order)::date AS cohort_month, count(*) AS cohort_size
FROM (SELECT user_id, min(created_at) AS first_order FROM orders WHERE status <> 'cancelled' GROUP BY user_id) f
GROUP BY 1 ORDER BY 1;
