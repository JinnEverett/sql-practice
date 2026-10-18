-- db: shop_s
-- ordered
-- Giải thích: CROSS JOIN khách × lịch tháng tạo đủ mọi cặp (5 khách × 6 tháng), rồi LEFT JOIN số đơn đã gom theo (khách, tháng VN).
--   Đây là mẫu "lưới đầy đủ" cho báo cáo có ô 0.
-- Bẫy: LEFT JOIN users → orders rồi GROUP BY tháng: tháng 0 đơn của khách không xuất hiện.
WITH months AS (
  SELECT m FROM generate_series(timestamp '2026-01-01', timestamp '2026-06-01', interval '1 month') AS m
), monthly AS (
  SELECT user_id, date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') AS m, count(*) AS n
  FROM orders
  WHERE user_id BETWEEN 21 AND 25
  GROUP BY 1, 2
)
SELECT u.id AS user_id, to_char(months.m, 'YYYY-MM') AS thang, coalesce(monthly.n, 0) AS n_orders
FROM users u
CROSS JOIN months
LEFT JOIN monthly ON monthly.user_id = u.id AND monthly.m = months.m
WHERE u.id BETWEEN 21 AND 25
ORDER BY user_id, thang;
