BEGIN;
:ans
;
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT id, payload FROM o05.big ORDER BY payload$$) AS p;
SELECT pg_temp.ck(pg_temp.has_node(p, 'Sort'), 'plan có node Sort') FROM p;
SELECT pg_temp.ck(pg_temp.temp_written(p) = 0, 'không ghi file tạm (temp blocks written = ' || pg_temp.temp_written(p) || ')') FROM p;
SELECT pg_temp.ck(pg_size_bytes(current_setting('work_mem')) <= 256 * 1024 * 1024, 'work_mem = ' || current_setting('work_mem') || ' (≤ 256MB)');
SELECT pg_temp.ck(pg_size_bytes(current_setting('work_mem')) > 4 * 1024 * 1024, 'đã nâng work_mem khỏi mặc định 4MB');
ROLLBACK;
