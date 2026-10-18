SELECT nam, method, n_payments, amount FROM (
  SELECT 0 AS g, extract(year FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::text AS nam, '(mọi phương thức)' AS method, count(*) AS n_payments, sum(amount) AS amount
  FROM payments WHERE status = 'succeeded' GROUP BY 2
  UNION ALL
  SELECT 1, '(mọi năm)', method, count(*), sum(amount) FROM payments WHERE status = 'succeeded' GROUP BY method
  UNION ALL
  SELECT 2, '(mọi năm)', '(mọi phương thức)', count(*), sum(amount) FROM payments WHERE status = 'succeeded') t
ORDER BY g, nam, method;
