-- db: shop_s
-- ordered
-- Giải thích: bước 1 (first_orders) tìm thời điểm đơn đầu tiên không bị hủy của mỗi khách. Bước 2 (new_customers) giữ khách có
--   đơn đầu nằm trong 9 tháng đầu 2026 và gắn cờ "có mua lại trong 30 ngày" bằng EXISTS. Bước cuối đếm theo tháng (giờ VN).
--   Mỗi CTE là một bước có tên, đọc như mô tả nghiệp vụ. Đây là lý do chính để dùng CTE.
-- Bẫy: tính đơn đầu có cả đơn cancelled; "trong 30 ngày" bắt đầu từ ngày 1 của tháng thay vì từ đơn đầu; đếm lại chính đơn đầu (> thay vì >=).
WITH first_orders AS (
  SELECT user_id, min(created_at) AS first_at
  FROM orders
  WHERE status <> 'cancelled'
  GROUP BY user_id
), new_customers AS (
  SELECT f.user_id, f.first_at,
         EXISTS (SELECT 1 FROM orders o
                 WHERE o.user_id = f.user_id AND o.status <> 'cancelled'
                   AND o.created_at > f.first_at
                   AND o.created_at <= f.first_at + interval '30 days') AS repeated
  FROM first_orders f
  WHERE f.first_at >= '2026-01-01 00:00+07' AND f.first_at < '2026-10-01 00:00+07'
)
SELECT to_char(date_trunc('month', first_at AT TIME ZONE 'Asia/Ho_Chi_Minh'), 'YYYY-MM') AS thang,
       count(*) AS n_new,
       count(*) FILTER (WHERE repeated) AS n_repeat_30d,
       round(100.0 * count(*) FILTER (WHERE repeated) / count(*), 1) AS pct_repeat
FROM new_customers
GROUP BY 1
ORDER BY 1;
