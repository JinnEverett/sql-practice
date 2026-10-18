-- db: lab
-- mode: check
-- reset
-- Giải thích: trong một transaction, một lệnh lỗi đặt cả transaction vào trạng thái "aborted" (ERROR: current transaction is aborted…) và mọi lệnh sau bị bỏ qua.
--   SAVEPOINT cho phép quay lại điểm trước lệnh lỗi mà giữ phần đã làm: ROLLBACK TO SAVEPOINT. Kết quả: 'B2' và 'C3' được ghi, 'A1' (trùng) bị bỏ qua, mọi thứ commit cùng lúc.
-- Bẫy: không có savepoint (lỗi của 'A1' làm mất cả B2 và C3); RELEASE sai chỗ; quên COMMIT.
BEGIN;
INSERT INTO p06.sku VALUES ('B2', 'hàng B');
SAVEPOINT s1;
INSERT INTO p06.sku VALUES ('A1', 'hàng A trùng mã');
ROLLBACK TO SAVEPOINT s1;
INSERT INTO p06.sku VALUES ('C3', 'hàng C');
COMMIT;
