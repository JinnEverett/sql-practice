SELECT d::date AS ngay, count(*) AS n_orders
FROM generate_series(date '2026-09-01', date '2026-09-30', interval '1 day') AS d
LEFT JOIN orders o ON o.user_id = 1 AND (o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date = d::date
GROUP BY d ORDER BY ngay;
