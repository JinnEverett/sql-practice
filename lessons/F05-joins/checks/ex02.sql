-- db: shop_s
-- ordered
SELECT oi.line_no, p.name AS product_name, c.name AS category_name, oi.quantity,
       oi.quantity * oi.unit_price AS line_total
FROM order_items oi
JOIN products p   ON p.id = oi.product_id
JOIN categories c ON c.id = p.category_id
WHERE oi.order_id = 1
ORDER BY oi.line_no;
