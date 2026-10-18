SELECT o.user_id, to_char(date_trunc('month', o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh'), 'YYYY-MM') AS thang, count(*) AS n_orders
FROM orders o WHERE o.user_id BETWEEN 21 AND 25 AND o.created_at >= '2026-01-01 00:00+07' AND o.created_at < '2026-07-01 00:00+07'
GROUP BY 1, 2 ORDER BY 1, 2;
