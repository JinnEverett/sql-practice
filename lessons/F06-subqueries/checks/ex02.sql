-- db: shop_s
-- ordered
SELECT o.id AS order_id, o.total_amount,
       (SELECT round(avg(total_amount), 2) FROM orders) AS avg_all,
       o.total_amount - (SELECT round(avg(total_amount), 2) FROM orders) AS diff
FROM orders o
WHERE o.id BETWEEN 5001 AND 5010
ORDER BY o.id;
