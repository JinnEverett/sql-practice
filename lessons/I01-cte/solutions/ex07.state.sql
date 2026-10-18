-- ordered
SELECT o.id, o.user_id, o.status, o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh' AS created_vn, o.total,
       i.line_no, i.product_id, i.quantity, i.unit_price
FROM i01.orders o JOIN i01.order_items i ON i.order_id = o.id
ORDER BY o.id, i.line_no;
