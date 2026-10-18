-- db: lab
-- mode: check
-- reset
-- Giải thích: CREATE INDEX CONCURRENTLY không chặn ghi nhưng nếu thất bại (ở đây vì email trùng lúc dựng UNIQUE) nó để lại một index INVALID: index vẫn tồn tại,
--   vẫn bị cập nhật ở mỗi lần ghi (tốn chi phí) nhưng KHÔNG được dùng để đọc. Tạo lại cùng tên sẽ báo "already exists". Quy trình đúng:
--   (1) xử lý dữ liệu vi phạm (giữ dòng có updated_at mới nhất, trùng thì id lớn nhất); (2) DROP INDEX CONCURRENTLY index invalid (không chặn ghi);
--   (3) CREATE UNIQUE INDEX CONCURRENTLY lại. Cả hai lệnh CONCURRENTLY không chạy được trong transaction block, nên bài này chạy từng lệnh riêng (autocommit).
-- Bẫy: bỏ qua index invalid (index mới cùng tên báo lỗi); CREATE UNIQUE INDEX thường (chặn ghi suốt thời gian dựng); xóa dữ liệu mà không có quy tắc giữ bản nào.
DELETE FROM r10.users u
USING r10.users k
WHERE u.email = k.email AND (u.updated_at, u.id) < (k.updated_at, k.id);
DROP INDEX CONCURRENTLY r10.users_email_uq;
CREATE UNIQUE INDEX CONCURRENTLY users_email_uq ON r10.users (email);
