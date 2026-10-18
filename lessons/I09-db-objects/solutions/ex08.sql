-- db: lab
-- mode: check
-- reset
-- Giải thích: CREATE OR REPLACE VIEW giữ nguyên OID nên các view phụ thuộc (v_big_orders) không bị ảnh hưởng. Nhưng nó chỉ cho phép
--   THÊM cột ở CUỐI, giữ nguyên tên, kiểu và thứ tự các cột cũ. Chèn cột vào giữa hoặc đổi kiểu → lỗi 42P16 ("cannot change name of view column").
--   Muốn đổi kiểu/thứ tự: DROP VIEW … CASCADE rồi tạo lại cả chuỗi view phụ thuộc, hoặc tạo view mới song song rồi chuyển dần.
-- Bẫy: DROP VIEW … CASCADE xóa luôn v_big_orders (ứng dụng khác đang dùng); chèn cột mới ở giữa.
CREATE OR REPLACE VIEW i09.v_order_summary AS
SELECT o.id AS order_id, c.name AS customer_name, o.total, o.status
FROM i09.orders o JOIN i09.customers c ON c.id = o.customer_id;
