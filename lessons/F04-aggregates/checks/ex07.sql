-- db: shop_s
-- ordered
SELECT coalesce(discount_code, '(không mã)') AS code_label, count(*) AS n_orders,
       round(avg(discount_amount), 0) AS avg_discount, sum(discount_amount) AS total_discount
FROM orders GROUP BY 1 ORDER BY n_orders DESC;
