-- db: shop_s
-- ordered
-- Giải thích: generate_series(date, date, interval) sinh đủ 30 ngày (kiểu timestamp, ép ::date). LEFT JOIN số đơn đã gom theo ngày VN.
--   Đây là cách "lấp khoảng trống" chuẩn: luôn bắt đầu từ bảng lịch, không bắt đầu từ bảng dữ liệu.
-- Bẫy: GROUP BY trên orders rồi mới nghĩ tới ngày trống (ngày 0 đơn không bao giờ xuất hiện); count(*) thay vì count(o.id) sau LEFT JOIN.
SELECT d::date AS ngay, count(o.id) AS n_orders
FROM generate_series(date '2026-09-01', date '2026-09-30', interval '1 day') AS d
LEFT JOIN orders o
  ON o.user_id = 1
 AND (o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date = d::date
GROUP BY d
ORDER BY ngay;
