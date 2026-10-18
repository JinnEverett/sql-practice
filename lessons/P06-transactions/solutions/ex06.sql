-- db: lab
-- mode: check
-- reset
-- Giải thích: write skew: hai transaction cùng đọc count = 2 rồi mỗi bên sửa một dòng KHÁC nhau, nên không có xung đột ghi-ghi; REPEATABLE READ hay READ COMMITTED đều để cả hai commit
--   → 0 bác sĩ trực. SERIALIZABLE (SSI) phát hiện vòng phụ thuộc rw và hủy một transaction với SQLSTATE 40001 — ứng dụng PHẢI retry. Phương án khác (alt1): khóa tập dòng bằng
--   SELECT … FOR UPDATE để tuần tự hóa, kèm điều kiện kiểm tra lại trong chính lệnh UPDATE (vì app không còn chạy lại phần quyết định).
-- Bẫy: REPEATABLE READ (tưởng đủ mạnh); khóa FOR UPDATE nhưng UPDATE không kiểm tra lại điều kiện; SERIALIZABLE mà không xử lý 40001 khi triển khai thật.
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) FROM p06.doctor WHERE on_call;
-- >>> B
UPDATE p06.doctor SET on_call = false WHERE id = :me;
COMMIT;
