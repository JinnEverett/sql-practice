-- sai: BETWEEN → đơn 2 và 4 (đúng thời điểm đổi giá) khớp 2 dòng lịch sử
SELECT o.id AS order_id, o.product_id, o.qty, ph.price AS unit_price, o.qty * ph.price AS amount
FROM r05.orders o
LEFT JOIN r05.price_history ph ON ph.product_id = o.product_id AND o.ordered_at BETWEEN ph.valid_from AND coalesce(ph.valid_to, 'infinity')
ORDER BY o.id, ph.price;
