-- db: shop_s
-- ordered
-- Giải thích: first_value lấy dòng đầu của frame; last_value lấy dòng CUỐI của frame. Frame mặc định (có ORDER BY) kết thúc
--   ở dòng hiện tại → last_value luôn = chính dòng đó. Phải mở frame tới cuối partition:
--   ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING.
--   Định nghĩa window một lần bằng mệnh đề WINDOW cho gọn.
-- Bẫy: last_value với frame mặc định (cột last_order_id trùng cột id).
SELECT id, created_at, total_amount,
       first_value(id) OVER w AS first_order_id,
       last_value(id)  OVER w AS last_order_id,
       max(total_amount) OVER w AS max_total
FROM orders
WHERE user_id = 1 AND created_at >= '2026-09-01 00:00+07' AND created_at < '2026-10-01 00:00+07'
WINDOW w AS (ORDER BY created_at, id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
ORDER BY created_at, id;
