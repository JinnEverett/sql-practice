-- db: shop_s
-- ordered
-- Giải thích: CTE item_sums gom dòng hàng theo đơn (1 dòng/đơn) rồi mới JOIN với orders → không nhân dòng.
--   expected = tổng dòng hàng + phí ship − giảm giá. Lọc các đơn lệch, sắp theo độ lệch tuyệt đối.
-- Bẫy: quên shipping_fee/discount_amount; JOIN order_items rồi so total_amount trên từng dòng hàng.
WITH item_sums AS (
  SELECT order_id, sum(quantity * unit_price) AS items_total
  FROM order_items
  GROUP BY order_id
)
SELECT o.id AS order_id,
       o.total_amount,
       s.items_total + o.shipping_fee - o.discount_amount AS expected,
       o.total_amount - (s.items_total + o.shipping_fee - o.discount_amount) AS diff
FROM orders o
JOIN item_sums s ON s.order_id = o.id
WHERE o.total_amount <> s.items_total + o.shipping_fee - o.discount_amount
ORDER BY abs(o.total_amount - (s.items_total + o.shipping_fee - o.discount_amount)) DESC, o.id;
