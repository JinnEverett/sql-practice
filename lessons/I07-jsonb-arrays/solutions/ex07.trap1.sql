SELECT order_id, array_agg(product_id ORDER BY product_id) AS product_ids
FROM order_items WHERE order_id IN (SELECT order_id FROM order_items WHERE product_id IN (1, 4))
GROUP BY order_id ORDER BY order_id;
