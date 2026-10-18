-- db: shop_s
-- ordered
-- Giải thích: mốc kiểm tra là hằng số timestamptz; trừ đi interval '3 days' cho ngưỡng. Hiệu hai timestamptz là interval;
--   date_trunc('hour', interval) cắt phần lẻ dưới giờ. justify_hours đổi "100 hours" thành "4 days 04:00:00" cho dễ đọc.
-- Bẫy: so với now() (kết quả đổi theo ngày chạy, không kiểm chứng được); quên trạng thái 'paid'.
SELECT id, status, created_at,
       justify_hours(date_trunc('hour', timestamptz '2026-10-01 00:00+07' - created_at)) AS waited
FROM orders
WHERE status IN ('pending', 'paid')
  AND created_at < timestamptz '2026-10-01 00:00+07' - interval '3 days'
ORDER BY created_at, id;
