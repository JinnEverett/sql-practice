-- db: shop_s
-- ordered
-- Giải thích: phần neo (anchor) là ngày đầu; phần đệ quy cộng 1 ngày cho tới khi chạm ngày cuối. Sau đó LEFT JOIN với số đơn
--   đã gom theo ngày (giờ VN) để ngày 0 đơn vẫn hiện. Thực tế dùng generate_series (I05) gọn hơn; bài này để luyện cơ chế đệ quy.
-- Bẫy: điều kiện dừng sai (< thay vì <=, hoặc quên điều kiện → vòng vô hạn); đếm theo ngày UTC.
WITH RECURSIVE days AS (
  SELECT date '2026-09-01' AS d
  UNION ALL
  SELECT d + 1 FROM days WHERE d < date '2026-09-30'
), daily AS (
  SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS d, count(*) AS n
  FROM orders
  WHERE created_at >= '2026-09-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
  GROUP BY 1
)
SELECT days.d AS ngay, coalesce(daily.n, 0) AS n_orders
FROM days LEFT JOIN daily ON daily.d = days.d
ORDER BY ngay;
