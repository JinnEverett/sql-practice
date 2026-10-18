-- db: shop_s
-- ordered
-- Giải thích: date_trunc('week', …) cắt về THỨ HAI đầu tuần (chuẩn ISO). to_char 'IYYY-"W"IW' cho năm ISO + số tuần ISO.
--   Dùng IYYY (năm ISO) chứ không phải YYYY: ngày 29/12 có thể thuộc tuần 1 của năm sau.
-- Bẫy: 'YYYY-"W"IW' (năm lịch + tuần ISO) sai quanh đầu/cuối năm; extract(week) theo UTC.
SELECT to_char(date_trunc('week', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh'), 'IYYY-"W"IW') AS tuan,
       date_trunc('week', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS thu_hai,
       count(*) AS n_orders,
       sum(total_amount) AS revenue
FROM orders
WHERE created_at >= '2026-07-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
  AND status NOT IN ('cancelled', 'refunded')
GROUP BY date_trunc('week', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')
ORDER BY thu_hai;
