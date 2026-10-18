-- sai: WAU = tổng DAU của 7 ngày → khách hoạt động nhiều ngày bị đếm nhiều lần
WITH o AS (SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day, count(DISTINCT user_id) AS dau FROM orders WHERE status <> 'cancelled' AND created_at >= '2026-08-25 00:00+07' AND created_at < '2026-10-01 00:00+07' GROUP BY 1),
days AS (SELECT d::date AS day FROM generate_series('2026-09-01'::date, '2026-09-30', interval '1 day') d)
SELECT days.day, coalesce(max(o.dau) FILTER (WHERE o.day = days.day), 0) AS dau, sum(o.dau) AS wau
FROM days LEFT JOIN o ON o.day BETWEEN days.day - 6 AND days.day GROUP BY days.day ORDER BY days.day;
