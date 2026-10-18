-- db: lab
-- mode: check
-- reset
-- Giải thích: "đọc rồi ghi lại giá trị đã tính ở app" (read-modify-write) làm mất cập nhật: A đọc 100, B cộng 50 → 150 rồi A ghi `130`, xóa mất phần của B (lost update).
--   Cách sửa gốc: để Postgres tính trong chính lệnh UPDATE (`balance = balance + 30`): lệnh đọc giá trị mới nhất của dòng đã bị khóa, sau khi chờ B nếu cần. Kết quả 180.
--   Phương án khác: khóa dòng ngay lúc đọc (SELECT … FOR UPDATE); lúc đó B chờ A commit rồi mới cộng 50.
-- Bẫy: UPDATE SET balance = 130 (số do app tính); REPEATABLE READ + UPDATE: lỗi 40001 "could not serialize access due to concurrent update" — phải retry, không được bỏ qua.
BEGIN;
SELECT balance FROM p06.acct WHERE id = 1;
-- >>> B
UPDATE p06.acct SET balance = balance + 30 WHERE id = 1;
COMMIT;
