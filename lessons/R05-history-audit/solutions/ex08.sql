-- db: shop_s
-- ordered
-- expect-rows: 24
-- Giải thích: users.deleted_at là soft delete nhưng orders vẫn tham chiếu user đó (FK không biết gì về deleted_at) và có đơn phát sinh SAU khi tài khoản bị xóa.
--   Giữ cả hai con số (tổng đơn và đơn sau xóa) trong một lần quét: LEFT JOIN rồi count(*) FILTER (WHERE …), thay vì đặt điều kiện vào WHERE
--   (làm mất đơn trước ngày xóa khỏi total_orders). LEFT JOIN giữ user đã xóa mà chưa có đơn nào (ở shop_s không có, nhưng đúng về nguyên tắc).
-- Bẫy: điều kiện thời gian trong WHERE → total_orders = orders_after_deletion; INNER JOIN làm mất user không có đơn; sum() trên tập rỗng là NULL (dùng coalesce nếu cần số 0).
SELECT u.id AS user_id,
       u.deleted_at,
       count(o.id) FILTER (WHERE o.created_at >= u.deleted_at)             AS orders_after_deletion,
       coalesce(sum(o.total_amount) FILTER (WHERE o.created_at >= u.deleted_at), 0) AS amount_after_deletion,
       count(o.id)                                                         AS total_orders
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.deleted_at IS NOT NULL
GROUP BY u.id, u.deleted_at
HAVING count(o.id) FILTER (WHERE o.created_at >= u.deleted_at) > 0
ORDER BY orders_after_deletion DESC, user_id;
