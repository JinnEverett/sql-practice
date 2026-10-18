-- db: lab
-- mode: manual
-- reset
-- Demo: tái hiện LOST UPDATE bằng hai session (dblink) rồi sửa. Mọi thứ tự động, in kết quả cuối cùng của hai cách.
CREATE EXTENSION IF NOT EXISTS dblink;
SELECT dblink_connect('a', 'dbname=lab user=postgres') AS _ \gset
SELECT dblink_connect('b', 'dbname=lab user=postgres') AS _ \gset

\echo '=== Cách SAI: đọc rồi ghi (read-modify-write ở phía ứng dụng)'
UPDATE r08.counters SET n = 0 WHERE id = 1;
SELECT dblink_exec('a', 'BEGIN') AS _ \gset
SELECT dblink_exec('b', 'BEGIN') AS _ \gset
SELECT n AS a_n FROM dblink('a', 'SELECT n FROM r08.counters WHERE id = 1') AS t(n int) \gset
SELECT n AS b_n FROM dblink('b', 'SELECT n FROM r08.counters WHERE id = 1') AS t(n int) \gset
-- A ghi 0 + 1
SELECT dblink_exec('a', format('UPDATE r08.counters SET n = %s WHERE id = 1', :a_n + 1)) AS _ \gset
SELECT dblink_exec('a', 'COMMIT') AS _ \gset
-- B ghi 0 + 1, đè mất lần cộng của A
SELECT dblink_exec('b', format('UPDATE r08.counters SET n = %s WHERE id = 1', :b_n + 1)) AS _ \gset
SELECT dblink_exec('b', 'COMMIT') AS _ \gset
SELECT n AS "n sau 2 lần cộng 1 (kỳ vọng 2)" FROM r08.counters WHERE id = 1;

\echo '=== Cách ĐÚNG: một câu UPDATE nguyên tử, để database tính n + 1'
UPDATE r08.counters SET n = 0 WHERE id = 1;
SELECT dblink_exec('a', 'BEGIN') AS _ \gset
SELECT dblink_exec('b', 'BEGIN') AS _ \gset
SELECT dblink_exec('a', 'UPDATE r08.counters SET n = n + 1 WHERE id = 1') AS _ \gset
-- B chờ khóa dòng của A
SELECT dblink_send_query('b', 'UPDATE r08.counters SET n = n + 1 WHERE id = 1') AS _ \gset
SELECT pg_sleep(0.3);
-- A commit: B được chạy tiếp và đọc giá trị n MỚI NHẤT
SELECT dblink_exec('a', 'COMMIT') AS _ \gset
SELECT r AS _ FROM dblink_get_result('b') AS t(r text) \gset
SELECT count(*) AS _ FROM dblink_get_result('b') AS t(r text) \gset
SELECT dblink_exec('b', 'COMMIT') AS _ \gset
SELECT n AS "n sau 2 lần cộng 1 (kỳ vọng 2)" FROM r08.counters WHERE id = 1;
SELECT dblink_disconnect('a') AS _ \gset
SELECT dblink_disconnect('b') AS _ \gset
