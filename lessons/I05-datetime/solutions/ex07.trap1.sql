SELECT p.method, count(*) AS n_orders,
       count(*) FILTER (WHERE p.created_at - o.created_at <= interval '15 minutes') AS n_within_15m,
       round(100.0 * count(*) FILTER (WHERE p.created_at - o.created_at <= interval '15 minutes') / count(*), 1) AS pct
FROM orders o JOIN payments p ON p.order_id = o.id AND p.status = 'succeeded'
WHERE o.created_at >= '2026-09-01 00:00+07' AND o.created_at < '2026-10-01 00:00+07' GROUP BY 1 ORDER BY 1;
