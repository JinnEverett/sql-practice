-- db: lab
-- mode: check
-- reset
-- Giải thích: BEGIN … COMMIT gom nhiều lệnh thành một đơn vị nguyên tử. Lệnh thứ ba vi phạm CHECK (balance >= 0) làm transaction ở trạng thái lỗi;
--   COMMIT của transaction đã lỗi thực chất là ROLLBACK, nên hai lệnh trước (trừ 80 của An, cộng 80 cho Bình) cũng bị hủy. Không có BEGIN (autocommit)
--   thì mỗi lệnh tự commit: tiền đã chuyển nhưng phí chưa thu và không có đường quay lại.
-- Bẫy: viết 3 lệnh liền nhau không có BEGIN; bắt lỗi rồi COMMIT từng phần.
BEGIN;
UPDATE p06.acct SET balance = balance - 80 WHERE id = 1;
UPDATE p06.acct SET balance = balance + 80 WHERE id = 2;
UPDATE p06.acct SET balance = balance - 30 WHERE id = 1;
COMMIT;
