SELECT id, (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS ngay,
       count(*) OVER (ORDER BY (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_orders
FROM orders WHERE created_at >= '2026-09-01 00:00+07' AND created_at < '2026-09-04 00:00+07' ORDER BY id;
