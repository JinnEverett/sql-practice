-- sai: JOIN rồi cộng → shipping_fee và discount_amount bị nhân theo số dòng hàng (fan-out)
SELECT o.id, o.total_amount,
       sum(oi.quantity * oi.unit_price + o.shipping_fee - o.discount_amount) AS expected_total,
       o.total_amount - sum(oi.quantity * oi.unit_price + o.shipping_fee - o.discount_amount) AS diff
FROM orders o JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.id
HAVING o.total_amount <> sum(oi.quantity * oi.unit_price + o.shipping_fee - o.discount_amount)
ORDER BY abs(o.total_amount - sum(oi.quantity * oi.unit_price + o.shipping_fee - o.discount_amount)) DESC, o.id;
