-- db: lab
-- mode: check
-- reset
-- Giải thích: A (1→2) khóa dòng 1 rồi chờ dòng 2; B (2→1) khóa dòng 2 rồi chờ dòng 1 → vòng chờ, Postgres phát hiện sau deadlock_timeout (1 giây) và hủy một bên (ERROR: deadlock detected, 40P01).
--   Cách chữa gốc: luôn lấy khóa theo cùng một thứ tự toàn cục (ở đây tăng dần theo id) TRƯỚC khi sửa. Khi đó B chờ A ở lệnh khóa đầu tiên, không ai giữ một khóa trong lúc chờ khóa kia.
-- Bẫy: bắt lỗi 40P01 rồi retry (chữa triệu chứng, vẫn mất 1 giây mỗi lần deadlock); chỉ khóa dòng nguồn trước (vẫn mỗi bên giữ một khóa và chờ khóa kia).
BEGIN;
SELECT id FROM p08.acct WHERE id IN (:from, :to) ORDER BY id FOR UPDATE;
UPDATE p08.acct SET balance = balance - 10 WHERE id = :from;
-- >>> B
UPDATE p08.acct SET balance = balance + 10 WHERE id = :to;
INSERT INTO p08.xfer_log VALUES (:from, :to);
COMMIT;
