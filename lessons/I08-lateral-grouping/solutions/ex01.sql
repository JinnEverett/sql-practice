-- db: shop_s
-- ordered
-- Giải thích: LATERAL cho subquery bên phải tham chiếu cột của bảng bên trái (u.id), chạy lại cho TỪNG khách.
--   Bên trong ORDER BY … LIMIT 2 lấy đúng 2 đơn mới nhất. Đây là cách viết top-N mỗi nhóm thứ hai (bên cạnh row_number ở I03);
--   với index (user_id, created_at DESC) nó chỉ đọc đúng 2 dòng mỗi khách (ex09).
-- Bẫy: JOIN thường không tham chiếu được u.id bên trong subquery ("invalid reference to FROM-clause entry");
--   LIMIT 2 đặt ngoài → chỉ 2 dòng cho cả kết quả.
SELECT u.id AS user_id, o.id AS order_id, o.created_at, o.total_amount
FROM users u
CROSS JOIN LATERAL (
  SELECT id, created_at, total_amount
  FROM orders
  WHERE user_id = u.id
  ORDER BY created_at DESC, id DESC
  LIMIT 2
) o
WHERE u.id <= 5
ORDER BY u.id, o.created_at DESC;
