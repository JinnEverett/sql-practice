-- db: shop_s
-- ordered
-- Giải thích: RANGE (mặc định) coi các dòng có CÙNG giá trị ORDER BY là "đồng hạng" (peers) và đưa tất cả vào frame cùng lúc.
--   count(*) OVER (ORDER BY ngay) vì vậy cho mỗi đơn số đơn tính tới HẾT ngày đó, đúng nghĩa "lũy kế theo ngày".
--   ROWS thì dừng ở chính dòng hiện tại → hai đơn cùng ngày nhận hai số khác nhau.
-- Bẫy: ORDER BY ngày, id (thêm id làm hết peers) hoặc ROWS → số lũy kế lệch trong cùng một ngày.
SELECT id, (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS ngay,
       count(*) OVER (ORDER BY (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date) AS cum_orders
FROM orders
WHERE created_at >= '2026-09-01 00:00+07' AND created_at < '2026-09-04 00:00+07'
ORDER BY id;
