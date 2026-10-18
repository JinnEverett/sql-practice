WITH h AS (SELECT extract(hour FROM created_at)::int AS gio, count(*) AS n FROM orders
           WHERE created_at >= '2026-01-01 00:00+07' AND created_at < '2027-01-01 00:00+07' GROUP BY 1)
SELECT g AS gio, coalesce(h.n, 0) AS n_orders, round(100.0 * coalesce(h.n, 0) / sum(coalesce(h.n, 0)) OVER (), 1) AS pct
FROM generate_series(0, 23) AS g LEFT JOIN h ON h.gio = g ORDER BY gio;
