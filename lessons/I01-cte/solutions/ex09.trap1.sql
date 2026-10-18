WITH item_sums AS (SELECT order_id, sum(quantity * unit_price) AS items_total FROM order_items GROUP BY order_id)
SELECT o.id AS order_id, o.total_amount, s.items_total AS expected, o.total_amount - s.items_total AS diff
FROM orders o JOIN item_sums s ON s.order_id = o.id
WHERE o.total_amount <> s.items_total ORDER BY abs(o.total_amount - s.items_total) DESC, o.id;
