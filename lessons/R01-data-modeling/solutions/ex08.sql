-- db: shop_s
-- ordered
-- Giải thích: total_amount là dữ liệu dẫn xuất (denormalized): nó phải bằng sum(quantity × unit_price) + shipping_fee − discount_amount.
--   Phải gom order_items trước (subquery/CTE) rồi mới JOIN; nếu JOIN trước rồi cộng, shipping_fee bị nhân lên theo số dòng hàng (fan-out).
--   Sắp xếp theo |chênh lệch| giảm dần để các ca nặng nhất lên đầu.
-- Bẫy: fan-out khi cộng shipping_fee; đơn không có dòng hàng nào (INNER JOIN làm mất đơn).
SELECT o.id, o.total_amount,
       coalesce(i.items_total, 0) + o.shipping_fee - o.discount_amount AS expected_total,
       o.total_amount - (coalesce(i.items_total, 0) + o.shipping_fee - o.discount_amount) AS diff
FROM orders o
LEFT JOIN (SELECT order_id, sum(quantity * unit_price) AS items_total FROM order_items GROUP BY order_id) i ON i.order_id = o.id
WHERE o.total_amount <> coalesce(i.items_total, 0) + o.shipping_fee - o.discount_amount
ORDER BY abs(o.total_amount - (coalesce(i.items_total, 0) + o.shipping_fee - o.discount_amount)) DESC, o.id;
