-- db: shop_s
-- ordered
-- Giải thích: lag(created_at) OVER (PARTITION BY user_id ORDER BY created_at, id) lấy thời điểm đơn liền trước của cùng khách.
--   Hiệu hai timestamptz là interval; extract(epoch …) / 86400 đổi ra số ngày. Đơn đầu tiên không có đơn trước → NULL.
-- Bẫy: thiếu PARTITION BY (ở đây chỉ 1 khách nên không lộ, nhưng sai khi mở rộng); ORDER BY id thay vì thời gian.
SELECT id, created_at,
       round(extract(epoch FROM created_at - lag(created_at) OVER w) / 86400, 1) AS days_since_prev
FROM orders
WHERE user_id = 25
WINDOW w AS (PARTITION BY user_id ORDER BY created_at, id)
ORDER BY created_at, id;
