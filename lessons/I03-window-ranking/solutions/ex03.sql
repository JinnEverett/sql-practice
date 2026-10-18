-- db: shop_s
-- ordered
-- Giải thích: ntile(4) chia các dòng đã sắp thành 4 nhóm SỐ LƯỢNG gần bằng nhau (chênh nhau tối đa 1). Nhóm 1 = chi tiêu cao nhất
--   vì ORDER BY total_spent DESC. Window function có thể dùng trên kết quả GROUP BY ngay trong cùng tầng SELECT.
-- Bẫy: ORDER BY tăng dần (nhóm 1 thành nhóm chi ít nhất); ntile chia theo SỐ DÒNG, không theo khoảng giá trị.
SELECT quartile, count(*) AS n_users, min(total_spent) AS min_spent, max(total_spent) AS max_spent
FROM (
  SELECT user_id, sum(total_amount) AS total_spent,
         ntile(4) OVER (ORDER BY sum(total_amount) DESC, user_id) AS quartile
  FROM orders
  WHERE status = 'delivered'
  GROUP BY user_id
) t
GROUP BY quartile
ORDER BY quartile;
