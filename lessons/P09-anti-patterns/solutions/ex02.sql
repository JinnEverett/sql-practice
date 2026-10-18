-- db: shop_m
-- mode: check
-- Giải thích: `user_id::text = '4242'` ép CỘT sang text (thường do ORM/driver gửi tham số kiểu chuỗi) nên index trên user_id không dùng được. Đưa hằng về kiểu của cột: `user_id = 4242`.
--   Index Scan 34 buffers thay vì Seq Scan 11 929. Quy tắc: so sánh cột với giá trị cùng kiểu; cast phía hằng, không cast phía cột.
-- Bẫy: giữ `::text` và chỉ tạo index trên user_id; so sánh numeric/bigint bị cast ngầm; tham số JDBC kiểu varchar.
CREATE INDEX ON orders (user_id);
-- query
SELECT id, total_amount FROM orders WHERE user_id = 4242;
