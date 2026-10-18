-- db: lab
-- mode: check
-- reset
-- Giải thích: nguyên tắc ít quyền nhất (least privilege): app chỉ cần đúng những gì nó làm. GRANT theo cột cho phép giấu password_hash:
--   SELECT (cột, …) ON bảng; lúc đó `SELECT *` bị từ chối (vì * gồm cả cột không có quyền), ứng dụng phải liệt kê cột.
--   UPDATE (status) cho phép sửa đúng cột đó. DELETE/TRUNCATE không được cấp thì không làm được. Role app là LOGIN nhưng không phải
--   superuser/createdb/createrole (mặc định của CREATE ROLE). Mật khẩu đặt qua PASSWORD hoặc \password, đừng ghi trong script.
-- Bẫy: GRANT ALL cho tiện; GRANT SELECT cả bảng customers (lộ password_hash); app đăng nhập bằng superuser/owner.
CREATE ROLE o01_app LOGIN;
GRANT USAGE ON SCHEMA o01 TO o01_app;
GRANT SELECT (id, tenant_id, name, email) ON o01.customers TO o01_app;
GRANT SELECT, INSERT ON o01.orders TO o01_app;
GRANT UPDATE (status) ON o01.orders TO o01_app;
