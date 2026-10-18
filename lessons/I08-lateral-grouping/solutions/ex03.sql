-- db: shop_s
-- ordered
-- Giải thích: pivot = biến giá trị của một cột (status) thành nhiều cột. Mỗi cột là count(*) FILTER (WHERE status = …).
--   Cột 'khac' gom các trạng thái còn lại. Cách này chạy một lần quét, không cần extension.
-- Bẫy: thiếu cột 'khac' làm tổng các cột không bằng n_orders; dùng sum(CASE …) cũng đúng nhưng dài hơn.
SELECT to_char(date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh'), 'YYYY-MM') AS thang,
       count(*) AS n_orders,
       count(*) FILTER (WHERE status = 'delivered') AS delivered,
       count(*) FILTER (WHERE status = 'cancelled') AS cancelled,
       count(*) FILTER (WHERE status = 'refunded') AS refunded,
       count(*) FILTER (WHERE status NOT IN ('delivered', 'cancelled', 'refunded')) AS khac
FROM orders
WHERE created_at >= '2026-07-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
GROUP BY 1
ORDER BY 1;
