SELECT coalesce(extract(year FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::text, '(mọi năm)') AS nam, coalesce(method, '(mọi phương thức)') AS method,
       count(*) AS n_payments, sum(amount) AS amount
FROM payments WHERE status = 'succeeded'
GROUP BY ROLLUP (extract(year FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh'), method) ORDER BY 1, 2;
