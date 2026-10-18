-- sai: mẫu số là số khách hoạt động ở tháng k (retention luôn gần 100%)
WITH o AS (SELECT user_id, date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS m FROM orders WHERE status <> 'cancelled' GROUP BY 1, 2),
first AS (SELECT user_id, min(m) AS cohort FROM o GROUP BY user_id),
grid AS (SELECT c AS cohort, k AS month_offset FROM generate_series('2026-01-01'::date, '2026-03-01', interval '1 month') c CROSS JOIN generate_series(0, 3) k)
SELECT g.cohort::date AS cohort_month, g.month_offset, count(o.user_id) AS active_users,
       round(100.0 * count(o.user_id) / nullif(count(o.user_id), 0), 1) AS retention_pct
FROM grid g JOIN first f ON f.cohort = g.cohort
LEFT JOIN o ON o.user_id = f.user_id AND o.m = (g.cohort + make_interval(months => g.month_offset))::date
GROUP BY g.cohort, g.month_offset ORDER BY 1, 2;
