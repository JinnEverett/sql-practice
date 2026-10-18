-- db: lab
-- mode: check
-- reset
-- Giải thích: ALTER DEFAULT PRIVILEGES định nghĩa quyền sẽ được cấp cho đối tượng TẠO SAU, theo từng (role tạo, schema).
--   Mặc định áp cho đối tượng do role đang chạy lệnh tạo ra (ở đây: người chạy bài). Muốn áp cho đối tượng do role khác tạo thì
--   thêm FOR ROLE <role_tạo>. Quyền hiện có vẫn cần GRANT thường; hai lệnh bổ sung nhau.
-- Bẫy: chỉ GRANT … ON ALL TABLES (bảng mới tạo sau không đọc được); ALTER DEFAULT PRIVILEGES cho role sai (không phải role tạo bảng).
CREATE ROLE o01_ro NOLOGIN;
GRANT USAGE ON SCHEMA o01 TO o01_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA o01 TO o01_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA o01 GRANT SELECT ON TABLES TO o01_ro;
