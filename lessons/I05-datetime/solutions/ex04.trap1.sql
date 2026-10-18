SELECT to_char(date_trunc('week', created_at), 'IYYY-"W"IW') AS tuan, date_trunc('week', created_at)::date AS thu_hai,
       count(*) AS n_orders, sum(total_amount) AS revenue
FROM orders WHERE created_at >= '2026-07-01 00:00+07' AND created_at < '2026-10-01 00:00+07' AND status NOT IN ('cancelled', 'refunded')
GROUP BY date_trunc('week', created_at) ORDER BY thu_hai;
