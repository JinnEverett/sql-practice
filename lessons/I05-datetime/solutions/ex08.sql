-- db: shop_s
-- ordered
-- Giải thích: thời gian từ lúc đăng ký tới đơn đầu tiên (mọi trạng thái), tính bằng ngày dạng số thập phân: extract(epoch …)/86400.
--   Khách đăng ký trong 2025 (giờ VN), gom theo tháng đăng ký. Khách chưa từng mua bị loại (INNER JOIN), đếm riêng ở n_never.
--   Lưu ý dữ liệu bẩn: có đơn tạo TRƯỚC ngày đăng ký → khoảng cách âm; đề yêu cầu bỏ các khách đó.
-- Bẫy: avg trên interval rồi để nguyên ("1 mon 3 days…" khó so); không loại khoảng âm.
WITH f AS (
  SELECT u.id, date_trunc('month', u.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') AS m,
         extract(epoch FROM min(o.created_at) - u.created_at) / 86400 AS days_to_first
  FROM users u
  LEFT JOIN orders o ON o.user_id = u.id
  WHERE u.created_at >= '2025-01-01 00:00+07' AND u.created_at < '2026-01-01 00:00+07'
  GROUP BY u.id, u.created_at
)
SELECT to_char(m, 'YYYY-MM') AS thang_dk,
       count(*) FILTER (WHERE days_to_first >= 0) AS n_users,
       count(*) FILTER (WHERE days_to_first IS NULL) AS n_never,
       round(avg(days_to_first) FILTER (WHERE days_to_first >= 0), 1) AS avg_days
FROM f
GROUP BY m
ORDER BY m;
