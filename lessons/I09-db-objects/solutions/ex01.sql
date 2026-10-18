-- db: lab
-- mode: check
-- reset
-- Giải thích: view là câu SELECT được đặt tên, KHÔNG lưu dữ liệu; mỗi lần đọc view, Postgres thay định nghĩa vào truy vấn (rewrite) rồi plan như bình thường.
--   Nên view luôn thấy dữ liệu mới nhất. Ngày theo giờ VN: created_at AT TIME ZONE 'Asia/Ho_Chi_Minh' cho timestamp không múi giờ, ép ::date.
-- Bẫy: ::date trực tiếp trên timestamptz dùng múi giờ của session (UTC) nên đơn lúc 00:30 giờ VN rơi vào ngày hôm trước; CREATE TABLE AS thay cho view (dữ liệu bị đóng băng).
CREATE VIEW i09.v_orders_vn AS
SELECT o.id AS order_id, c.name AS customer_name, o.status, o.total,
       (o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS order_date
FROM i09.orders o
JOIN i09.customers c ON c.id = o.customer_id
WHERE o.status <> 'cancelled';
