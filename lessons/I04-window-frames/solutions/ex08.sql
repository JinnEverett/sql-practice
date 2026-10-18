-- db: shop_s
-- ordered
-- Giải thích: bước 1: với mỗi đơn delivered tính khoảng cách (ngày) tới đơn delivered trước của cùng khách (lag).
--   Bước 2: mỗi khách lấy số đơn, khoảng cách trung bình (avg bỏ NULL của đơn đầu), và khoảng cách CUỐI = khoảng cách của đơn
--   mới nhất (row_number giảm dần = 1). Bước 3: lọc khách có ≥ 3 đơn và last_gap > 3 × avg_gap.
-- Bẫy: avg_gap chia cho số đơn thay vì số khoảng cách; lấy max(gap) thay vì gap của đơn cuối.
WITH g AS (
  SELECT user_id, created_at,
         extract(epoch FROM created_at - lag(created_at) OVER (PARTITION BY user_id ORDER BY created_at, id)) / 86400 AS gap_days,
         row_number() OVER (PARTITION BY user_id ORDER BY created_at DESC, id DESC) AS rn_desc
  FROM orders
  WHERE status = 'delivered'
), per_user AS (
  SELECT user_id, count(*) AS n_orders,
         avg(gap_days) AS avg_gap,
         max(gap_days) FILTER (WHERE rn_desc = 1) AS last_gap
  FROM g
  GROUP BY user_id
)
SELECT user_id, n_orders, round(avg_gap, 1) AS avg_gap_days, round(last_gap, 1) AS last_gap_days
FROM per_user
WHERE n_orders >= 3 AND last_gap > 3 * avg_gap
ORDER BY last_gap / avg_gap DESC, user_id;
