-- db: lab
-- mode: check
-- reset
-- Giải thích: quyền trong Postgres đi theo từng tầng: để đọc o01.orders, role cần USAGE trên SCHEMA (được "đi vào" schema)
--   VÀ SELECT trên TABLE. NOLOGIN: role chỉ để gom quyền, người/app đăng nhập bằng role khác được GRANT vào nó.
--   GRANT … ON ALL TABLES IN SCHEMA chỉ áp cho bảng ĐÃ có tại thời điểm chạy lệnh (bảng tạo sau: ex02).
-- Bẫy: chỉ GRANT SELECT mà quên USAGE trên schema → "permission denied for schema o01"; cấp SELECT cho PUBLIC.
CREATE ROLE o01_ro NOLOGIN;
GRANT USAGE ON SCHEMA o01 TO o01_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA o01 TO o01_ro;
