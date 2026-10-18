-- db: shop_s
-- ordered
SELECT order_id, count(*) AS n_lines, sum(quantity) AS total_qty,
       string_agg(product_id::text, ',' ORDER BY line_no) AS product_ids
FROM order_items WHERE order_id BETWEEN 1 AND 10 GROUP BY order_id ORDER BY order_id;
