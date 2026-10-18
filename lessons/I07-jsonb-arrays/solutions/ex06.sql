-- db: shop_s
-- ordered
-- Giải thích: jsonb_build_object(k1, v1, k2, v2, …) dựng object; jsonb_agg(x ORDER BY …) gom nhiều dòng thành mảng JSON.
--   Gom dòng hàng theo đơn trong subquery, rồi dựng tài liệu cấp đơn. Đây là cách trả "đơn kèm chi tiết" cho API trong 1 query.
-- Bẫy: jsonb_agg không ORDER BY → thứ tự items không xác định; JOIN rồi mới aggregate ở tầng ngoài làm lặp thông tin đơn.
SELECT o.id AS order_id,
       jsonb_build_object(
         'order_id', o.id,
         'status', o.status,
         'total', o.total_amount,
         'items', (SELECT jsonb_agg(jsonb_build_object('line', oi.line_no, 'product_id', oi.product_id,
                                                       'qty', oi.quantity, 'price', oi.unit_price)
                                    ORDER BY oi.line_no)
                   FROM order_items oi WHERE oi.order_id = o.id)
       ) AS doc
FROM orders o
WHERE o.id <= 3
ORDER BY o.id;
