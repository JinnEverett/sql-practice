-- db: shop_m
-- mode: check
-- Giải thích: OR giữa điều kiện của HAI bảng sau join: planner không tách được thành hai đường index, phải join cả 1M đơn rồi lọc. Tách thành hai nhánh mỗi nhánh index-friendly rồi UNION (loại trùng):
--   nhánh 1 tra PK orders; nhánh 2 tra users(email) rồi orders(user_id). 119 dòng trong 132 buffers (thay vì quét cả 1M đơn).
-- Bẫy: chỉ thêm index mà giữ nguyên OR; UNION ALL làm trùng nếu đơn 123456 thuộc chính khách đó; quên index trên users(email) hoặc orders(user_id).
CREATE INDEX ON users (email);
CREATE INDEX ON orders (user_id);
-- query
SELECT id FROM orders WHERE id = 123456
UNION
SELECT o.id FROM users u JOIN orders o ON o.user_id = u.id WHERE u.email = 'nhung.le500@outlook.com';
