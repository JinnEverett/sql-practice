-- db: shop_s
-- ordered
-- Giải thích: ntile(100) chia khách đã sắp theo chi tiêu giảm dần thành 100 phần bằng nhau về số người: phần 1 = top 1%.
--   CASE gán nhóm, rồi gom. Tỉ trọng doanh thu dùng sum(...) OVER () (window không PARTITION = toàn bộ kết quả) để lấy tổng.
-- Bẫy: dùng percent_rank/cume_dist mà nhầm chiều; chia tỉ trọng trên số khách thay vì doanh thu.
WITH spent AS (
  SELECT user_id, sum(total_amount) AS total_spent,
         ntile(100) OVER (ORDER BY sum(total_amount) DESC, user_id) AS pct_bucket
  FROM orders
  WHERE status = 'delivered'
  GROUP BY user_id
)
SELECT nhom, count(*) AS n_users, sum(total_spent) AS revenue,
       round(100.0 * sum(total_spent) / sum(sum(total_spent)) OVER (), 1) AS pct_revenue
FROM (
  SELECT CASE WHEN pct_bucket = 1 THEN 'top 1%' WHEN pct_bucket <= 10 THEN 'top 2-10%' ELSE 'còn lại' END AS nhom,
         total_spent, pct_bucket
  FROM spent
) t
GROUP BY nhom
ORDER BY min(pct_bucket);
