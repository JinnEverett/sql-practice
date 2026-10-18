WITH p AS (SELECT method, amount, status FROM payments WHERE created_at >= '2026-01-01 00:00+07' AND created_at < '2027-01-01 00:00+07'),
total AS (SELECT sum(amount) AS s FROM p)
SELECT method, count(*) FILTER (WHERE status = 'succeeded') AS n_payments, sum(amount) FILTER (WHERE status = 'succeeded') AS amount,
       round(100.0 * sum(amount) FILTER (WHERE status = 'succeeded') / (SELECT s FROM total), 1) AS pct
FROM p GROUP BY method ORDER BY amount DESC;
