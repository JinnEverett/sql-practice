-- db: shop_s
-- ordered
SELECT method, count(*) AS n_payments, count(*) FILTER (WHERE status = 'succeeded') AS n_succeeded,
       round(count(*) FILTER (WHERE status = 'succeeded') * 100.0 / count(*), 2) AS success_rate
FROM payments GROUP BY method ORDER BY success_rate DESC, method;
