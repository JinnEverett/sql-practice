-- db: lab
-- reset
-- ordered
-- expect-rows: 7
-- Giải thích: giá tại thời điểm đặt hàng = dòng lịch sử có valid_from <= ordered_at < valid_to (khoảng NỬA MỞ [from, to), valid_to NULL = chưa hết hạn).
--   Nửa mở đảm bảo mỗi thời điểm khớp đúng MỘT dòng, kể cả đúng lúc đổi giá (đơn 2 và 4 đặt đúng 0h ngày đổi giá → lấy giá MỚI).
--   LEFT JOIN để đơn đặt trước khi sản phẩm có giá (đơn 7) vẫn hiện với giá NULL thay vì biến mất.
-- Bẫy: BETWEEN (đóng cả hai đầu) → đơn đúng ngày đổi giá khớp 2 dòng, bị nhân đôi; dùng giá hiện tại (valid_to IS NULL) → doanh thu quá khứ đổi theo giá mới.
SELECT o.id AS order_id, o.product_id, o.qty, ph.price AS unit_price, o.qty * ph.price AS amount
FROM r05.orders o
LEFT JOIN r05.price_history ph
  ON ph.product_id = o.product_id
 AND o.ordered_at >= ph.valid_from
 AND o.ordered_at <  coalesce(ph.valid_to, 'infinity')
ORDER BY o.id;
