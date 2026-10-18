-- db: shop_s
-- ordered
-- Giải thích: payment trùng = đơn có ≥ 2 payment 'succeeded'. Giữ bản đầu tiên (created_at nhỏ nhất, trùng thì id nhỏ nhất), các bản sau là ứng viên hoàn tiền.
--   row_number() OVER (PARTITION BY order_id ORDER BY created_at, id) trên tập đã lọc status = 'succeeded'; rn > 1 là bản trùng.
--   Khoảng cách tới bản đầu: created_at - first_value(created_at) OVER (cùng cửa sổ).
-- Bẫy: lọc status SAU khi đánh số (bản failed chen vào làm rn lệch); dùng id thay vì created_at để xác định "đầu tiên" (id và thời gian cùng chiều ở shop_*, nhưng đừng dựa vào).
SELECT order_id, id AS payment_id, amount,
       extract(epoch FROM created_at - first_created)::int AS seconds_after_first
FROM (
  SELECT p.*,
         row_number() OVER w AS rn,
         first_value(created_at) OVER w AS first_created
  FROM payments p
  WHERE status = 'succeeded'
  WINDOW w AS (PARTITION BY order_id ORDER BY created_at, id)
) t
WHERE rn > 1
ORDER BY order_id, payment_id;
