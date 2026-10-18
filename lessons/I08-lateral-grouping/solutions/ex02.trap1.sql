SELECT country, status, count(*) AS n_orders
FROM orders o JOIN users u ON u.id = o.user_id
WHERE o.created_at >= '2026-07-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07' AND u.country IN ('JP', 'SG')
GROUP BY country, status ORDER BY country, status;
