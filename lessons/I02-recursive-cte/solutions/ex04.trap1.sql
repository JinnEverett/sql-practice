SELECT r.name AS root_name, sum(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi JOIN orders o ON o.id = oi.order_id AND o.status = 'delivered'
JOIN products p ON p.id = oi.product_id JOIN categories c ON c.id = p.category_id JOIN categories r ON r.id = c.parent_id
GROUP BY r.name ORDER BY revenue DESC;
