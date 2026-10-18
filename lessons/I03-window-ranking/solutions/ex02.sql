-- db: shop_s
-- ordered
-- Giải thích: ba hàm khác nhau ở cách xử lý giá trị BẰNG nhau:
--   row_number: luôn 1,2,3… (hòa thì tùy ORDER BY phụ); rank: hòa cùng hạng rồi NHẢY (1,1,3); dense_rank: hòa cùng hạng, KHÔNG nhảy (1,1,2).
--   Lọc theo dense_rank ở tầng ngoài.
-- Bẫy: lọc bằng rank <= 5 (ra ít hạng hơn vì rank nhảy số); quên khách ở 'Huế' có thể có city NULL… (không ảnh hưởng ở đây).
SELECT user_id, n_orders, rnk, drnk, rn
FROM (
  SELECT o.user_id, count(*) AS n_orders,
         rank()       OVER (ORDER BY count(*) DESC) AS rnk,
         dense_rank() OVER (ORDER BY count(*) DESC) AS drnk,
         row_number() OVER (ORDER BY count(*) DESC, o.user_id) AS rn
  FROM orders o
  JOIN users u ON u.id = o.user_id
  WHERE u.city = 'Huế' AND o.status = 'delivered'
  GROUP BY o.user_id
) t
WHERE drnk <= 5
ORDER BY rn;
