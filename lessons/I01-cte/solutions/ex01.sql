-- db: shop_s
-- ordered
-- Giải thích: CTE user_totals được đọc HAI lần (lọc và tính trung bình). Không có CTE thì phải viết lặp lại subquery gom nhóm.
--   avg(total_spent) là trung bình THEO KHÁCH (mỗi khách một số), khác avg(total_amount) trên đơn.
-- Bẫy: so với avg(total_amount) của từng đơn (trung bình theo đơn, nhỏ hơn nhiều); quên lọc delivered ở CTE.
WITH user_totals AS (
  SELECT user_id, sum(total_amount) AS total_spent
  FROM orders
  WHERE status = 'delivered'
  GROUP BY user_id
)
SELECT user_id, total_spent
FROM user_totals
WHERE total_spent > 3 * (SELECT avg(total_spent) FROM user_totals)
ORDER BY total_spent DESC, user_id;
