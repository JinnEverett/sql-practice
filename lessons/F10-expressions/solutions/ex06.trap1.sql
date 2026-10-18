SELECT to_char(date_trunc('month', created_at), 'MM/YYYY') AS thang, count(*) AS n_orders,
       replace(to_char(sum(total_amount), 'FM999,999,999,999'), ',', '.') || ' ₫' AS doanh_thu
FROM orders
WHERE created_at >= '2026-01-01 00:00+07' AND created_at < '2027-01-01 00:00+07' AND status NOT IN ('cancelled', 'refunded')
GROUP BY date_trunc('month', created_at) ORDER BY date_trunc('month', created_at);
