SELECT o.id AS order_id,
       jsonb_build_object('order_id', o.id, 'status', o.status, 'total', o.total_amount,
         'items', (SELECT jsonb_agg(jsonb_build_object('line', oi.line_no, 'product_id', oi.product_id, 'qty', oi.quantity, 'price', oi.unit_price)
                                    ORDER BY oi.product_id) FROM order_items oi WHERE oi.order_id = o.id)) AS doc
FROM orders o WHERE o.id <= 3 ORDER BY o.id;
