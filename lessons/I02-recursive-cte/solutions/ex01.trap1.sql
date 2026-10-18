WITH RECURSIVE days AS (SELECT date '2026-09-01' AS d UNION ALL SELECT d + 1 FROM days WHERE d < date '2026-09-30'),
daily AS (SELECT created_at::date AS d, count(*) AS n FROM orders WHERE created_at >= '2026-09-01 00:00+07' AND created_at < '2026-10-01 00:00+07' GROUP BY 1)
SELECT days.d AS ngay, coalesce(daily.n, 0) AS n_orders FROM days LEFT JOIN daily ON daily.d = days.d ORDER BY ngay;
