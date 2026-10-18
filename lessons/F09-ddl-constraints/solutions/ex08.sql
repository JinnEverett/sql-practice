-- db: lab
-- mode: check
-- reset
-- Giải thích: FK tự tham chiếu + ON DELETE SET NULL giữ nhân viên khi quản lý nghỉ. CHECK (manager_id <> id) chặn tự quản lý
--   (manager_id NULL → CHECK ra NULL → hợp lệ, đúng ý). UNIQUE mặc định coi các NULL là KHÁC nhau → nhiều người chưa có email vẫn được.
-- Bẫy: ON DELETE CASCADE (xóa sếp là xóa cả phòng ban); UNIQUE NULLS NOT DISTINCT (Postgres 15+) chỉ cho đúng một người thiếu email.
CREATE TABLE f09.employees (
  id         int PRIMARY KEY,
  full_name  text NOT NULL,
  manager_id int REFERENCES f09.employees (id) ON DELETE SET NULL,
  work_email text UNIQUE,
  CHECK (manager_id <> id)
);
CREATE INDEX ON f09.employees (manager_id);
