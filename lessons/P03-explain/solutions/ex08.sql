-- db: lab
-- mode: check
-- reset
-- Giải thích: ANALYZE chạy câu UPDATE thật (trigger bắn 100 lần, sequence không rollback được nên check thấy 100). Bọc trong BEGIN … ROLLBACK để dữ liệu nguyên vẹn.
--   Cách khác: chạy trong transaction mở sẵn rồi ROLLBACK; hoặc với DML ghi vào bảng thật, thử trên bản sao.
-- Bẫy: EXPLAIN UPDATE (không ANALYZE) → không có số đo thật (trigger không chạy); EXPLAIN ANALYZE UPDATE trần → dữ liệu bị sửa thật; BEGIN mà quên ROLLBACK.
BEGIN;
EXPLAIN (ANALYZE, BUFFERS) UPDATE p03.acct SET balance = balance + 1 WHERE id <= 100;
ROLLBACK;
