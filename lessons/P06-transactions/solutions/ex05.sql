-- db: lab
-- mode: check
-- reset
-- Giải thích: phantom read = cùng một điều kiện, lần sau ra thêm dòng do giao dịch khác vừa commit. Chuẩn SQL chỉ chặn ở SERIALIZABLE, nhưng REPEATABLE READ của Postgres
--   là snapshot isolation nên đã chặn: cả hai lần đếm cùng snapshot → 2. READ COMMITTED: lần hai đếm 3.
-- Bẫy: giữ mặc định READ COMMITTED; tin rằng "phantom chỉ chặn được bằng SERIALIZABLE" (đúng với chuẩn, không đúng với Postgres).
BEGIN ISOLATION LEVEL REPEATABLE READ;
INSERT INTO p06.reads SELECT 1, count(*) FROM p06.ticket WHERE status = 'open';
-- >>> B
INSERT INTO p06.reads SELECT 2, count(*) FROM p06.ticket WHERE status = 'open';
COMMIT;
