-- db: shop_s
-- ordered
SELECT o.id AS order_id, o.total_amount, i.n_lines, coalesce(p.total_paid, 0) AS total_paid
FROM orders o
JOIN (SELECT order_id, count(*) AS n_lines FROM order_items GROUP BY order_id) i ON i.order_id = o.id
LEFT JOIN (SELECT order_id, sum(amount) AS total_paid FROM payments WHERE status = 'succeeded' GROUP BY order_id) p
       ON p.order_id = o.id
WHERE o.id BETWEEN 1685 AND 1694
ORDER BY o.id;
