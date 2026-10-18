-- sai: dùng giá hiện tại
SELECT o.id AS order_id, o.product_id, o.qty, ph.price AS unit_price, o.qty * ph.price AS amount
FROM r05.orders o
LEFT JOIN r05.price_history ph ON ph.product_id = o.product_id AND ph.valid_to IS NULL
ORDER BY o.id;
