-- db: shop_s
-- ordered
-- Giải thích: doanh thu lịch sử phải tính bằng order_items.unit_price (giá LÚC MUA). Dùng products.price (giá hiện tại) sẽ lệch mỗi khi đổi giá.
--   Đây là chỗ denormalize có chủ ý: unit_price lặp lại thông tin "giá" nhưng là sự kiện lịch sử, không phải bản sao dư thừa.
--   Tháng theo giờ Việt Nam: date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh').
-- Bẫy: JOIN products lấy price hiện tại; quên loại đơn cancelled/refunded; tháng theo UTC (đơn đêm 31 rơi sang tháng khác).
SELECT date_trunc('month', o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS month,
       sum(oi.unit_price * oi.quantity) AS revenue_at_purchase,
       sum(p.price * oi.quantity)       AS revenue_at_current_price,
       sum(oi.unit_price * oi.quantity) - sum(p.price * oi.quantity) AS diff
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id = oi.product_id
WHERE o.status NOT IN ('cancelled', 'refunded')
  AND o.created_at >= '2026-01-01 00:00+07' AND o.created_at < '2026-04-01 00:00+07'
GROUP BY 1
ORDER BY 1;
