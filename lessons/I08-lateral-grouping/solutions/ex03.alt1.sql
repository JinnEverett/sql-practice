SELECT to_char(date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh'), 'YYYY-MM') AS thang, count(*) AS n_orders,
       sum(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END) AS delivered,
       sum(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled,
       sum(CASE WHEN status = 'refunded' THEN 1 ELSE 0 END) AS refunded,
       sum(CASE WHEN status IN ('pending', 'paid', 'shipped') THEN 1 ELSE 0 END) AS khac
FROM orders WHERE created_at >= '2026-07-01 00:00+07' AND created_at < '2026-10-01 00:00+07' GROUP BY 1 ORDER BY 1;
