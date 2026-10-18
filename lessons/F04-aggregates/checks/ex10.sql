-- db: shop_s
-- ordered
SELECT order_id, count(*) AS n_succeeded, sum(amount) AS total_paid
FROM payments WHERE status = 'succeeded' GROUP BY order_id HAVING count(*) >= 2 ORDER BY order_id;
