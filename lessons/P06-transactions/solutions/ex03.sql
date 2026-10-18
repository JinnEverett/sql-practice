-- db: lab
-- mode: check
-- reset
-- Giải thích: ở READ COMMITTED (mặc định) MỖI LỆNH thấy một snapshot mới: lần đọc thứ hai thấy 150 (non-repeatable read). REPEATABLE READ chụp snapshot một lần
--   ở lệnh đầu tiên của transaction: hai lần đọc cùng 100 dù B đã commit. Postgres không có READ UNCOMMITTED thật: nó chạy như READ COMMITTED nên cũng không ngăn được.
--   SERIALIZABLE cũng đạt (mạnh hơn). Khóa FOR SHARE ở lần đọc đầu cũng được (B phải chờ A commit).
-- Bẫy: BEGIN trơn; READ UNCOMMITTED; quên chia script bằng dòng `-- >>> B`.
BEGIN ISOLATION LEVEL REPEATABLE READ;
INSERT INTO p06.reads SELECT 1, balance FROM p06.acct WHERE id = 1;
-- >>> B
INSERT INTO p06.reads SELECT 2, balance FROM p06.acct WHERE id = 1;
COMMIT;
