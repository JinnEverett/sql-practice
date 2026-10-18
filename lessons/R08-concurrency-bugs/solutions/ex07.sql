-- db: lab
-- mode: manual
-- reset
-- Demo: cùng một kịch bản write skew (hai bác sĩ cùng xin nghỉ trực) chạy ở REPEATABLE READ rồi SERIALIZABLE bằng hai session dblink.
CREATE EXTENSION IF NOT EXISTS dblink;
SELECT dblink_connect('a', 'dbname=lab user=postgres') AS _ \gset
SELECT dblink_connect('b', 'dbname=lab user=postgres') AS _ \gset

\echo '=== REPEATABLE READ: cả hai commit được, không còn ai trực'
SELECT dblink_exec('a', 'BEGIN ISOLATION LEVEL REPEATABLE READ') AS _ \gset
SELECT dblink_exec('b', 'BEGIN ISOLATION LEVEL REPEATABLE READ') AS _ \gset
SELECT n AS a_sees FROM dblink('a', 'SELECT count(*) FROM r08.doctors WHERE on_call') AS t(n int) \gset
SELECT n AS b_sees FROM dblink('b', 'SELECT count(*) FROM r08.doctors WHERE on_call') AS t(n int) \gset
SELECT dblink_exec('a', 'UPDATE r08.doctors SET on_call = false WHERE id = 1') AS _ \gset
SELECT dblink_exec('b', 'UPDATE r08.doctors SET on_call = false WHERE id = 2') AS _ \gset
SELECT dblink_exec('a', 'COMMIT') AS a_commit \gset
SELECT dblink_exec('b', 'COMMIT') AS b_commit \gset
SELECT :a_sees AS a_thay_con_truc, :b_sees AS b_thay_con_truc, :'a_commit' AS a, :'b_commit' AS b, (SELECT count(*) FROM r08.doctors WHERE on_call) AS con_truc_sau_cung;

\echo '=== SERIALIZABLE: một trong hai bị hủy với 40001'
UPDATE r08.doctors SET on_call = (id IN (1, 2));
SELECT dblink_exec('a', 'BEGIN ISOLATION LEVEL SERIALIZABLE') AS _ \gset
SELECT dblink_exec('b', 'BEGIN ISOLATION LEVEL SERIALIZABLE') AS _ \gset
SELECT n AS a_sees FROM dblink('a', 'SELECT count(*) FROM r08.doctors WHERE on_call') AS t(n int) \gset
SELECT n AS b_sees FROM dblink('b', 'SELECT count(*) FROM r08.doctors WHERE on_call') AS t(n int) \gset
SELECT dblink_exec('a', 'UPDATE r08.doctors SET on_call = false WHERE id = 1') AS _ \gset
SELECT dblink_exec('b', 'UPDATE r08.doctors SET on_call = false WHERE id = 2') AS _ \gset
SELECT dblink_exec('a', 'COMMIT') AS a_commit \gset
DO $d$
BEGIN
  PERFORM dblink_exec('b', 'COMMIT');
  RAISE NOTICE 'B commit: OK (không mong đợi)';
EXCEPTION WHEN others THEN
  RAISE NOTICE 'B commit: lỗi % (%)', SQLSTATE, SQLERRM;
END $d$;
SELECT dblink_exec('b', 'ROLLBACK') AS _ \gset
SELECT :'a_commit' AS a, (SELECT count(*) FROM r08.doctors WHERE on_call) AS con_truc_sau_cung;

\echo '=== Retry của B: giao dịch mới thấy A đã nghỉ nên tự từ chối'
SELECT dblink_exec('b', 'BEGIN ISOLATION LEVEL SERIALIZABLE') AS _ \gset
SELECT n AS b_sees_retry FROM dblink('b', 'SELECT count(*) FROM r08.doctors WHERE on_call') AS t(n int) \gset
SELECT :b_sees_retry AS b_thay_con_truc_o_lan_thu_2;
SELECT dblink_exec('b', 'ROLLBACK') AS _ \gset
SELECT dblink_disconnect('a') AS _ \gset
SELECT dblink_disconnect('b') AS _ \gset
