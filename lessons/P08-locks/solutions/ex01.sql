-- db: lab
-- ordered
-- expect-rows: 5
-- Giải thích: mỗi lệnh lấy một lock mức bảng (đo bằng pg_locks trong chính transaction): SELECT → AccessShare (chỉ xung đột với AccessExclusive); SELECT FOR UPDATE → RowShare;
--   UPDATE → RowExclusive (không chặn nhau ở mức bảng; chặn nhau ở mức DÒNG); CREATE INDEX → Share (chặn mọi INSERT/UPDATE/DELETE trên bảng, vì thế có CONCURRENTLY);
--   ALTER TABLE ADD COLUMN → AccessExclusive (chặn cả SELECT). Lock dòng không hiện ở pg_locks, nằm trong header tuple (xmax).
-- Bẫy: tưởng UPDATE khóa cả bảng; tưởng SELECT không lấy lock nào; CREATE INDEX thường chặn ghi.
SELECT * FROM (VALUES
  ('SELECT',                 'AccessShareLock'),
  ('SELECT FOR UPDATE',      'RowShareLock'),
  ('UPDATE',                 'RowExclusiveLock'),
  ('CREATE INDEX',           'ShareLock'),
  ('ALTER TABLE ADD COLUMN', 'AccessExclusiveLock')
) AS x(stmt, table_lock_mode) ORDER BY 2, 1;
