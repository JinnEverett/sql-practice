-- db: lab
-- ordered
SELECT order_id, total, n,
       round(total::numeric / n)                     AS per_installment,
       total - round(total::numeric / n) * (n - 1)   AS last_installment
FROM f02.installment_plans ORDER BY order_id;
