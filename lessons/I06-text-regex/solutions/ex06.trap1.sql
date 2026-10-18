SELECT oi.order_id, count(*) AS n_lines, string_agg(p.name || ' × ' || oi.quantity, ', ' ORDER BY p.name) AS items
FROM order_items oi JOIN products p ON p.id = oi.product_id WHERE oi.order_id <= 5 GROUP BY oi.order_id ORDER BY oi.order_id;
