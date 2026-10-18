BEGIN;
:ans
;
SELECT pg_temp.ck((SELECT count(*) FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'orders') = 2, 'đúng một index mới (ngoài orders_pkey)');
CREATE TEMP TABLE pa AS SELECT pg_temp.plan($$SELECT id FROM orders WHERE user_id = 4242$$) AS p;
CREATE TEMP TABLE pb AS SELECT pg_temp.plan($$SELECT id FROM orders WHERE user_id = 4242 AND status = 'delivered'$$) AS p;
CREATE TEMP TABLE pc AS SELECT pg_temp.plan($$SELECT id FROM orders WHERE user_id = 4242 AND created_at >= '2026-01-01' AND created_at < '2026-04-01'$$) AS p;
SELECT pg_temp.ck(pg_temp.rows_out(p) = 28 AND pg_temp.buffers(p) < 100, '(a) 28 dòng, ' || pg_temp.buffers(p) || ' buffers (< 100)') FROM pa;
SELECT pg_temp.ck(pg_temp.rows_out(p) = 25 AND pg_temp.buffers(p) < 100, '(b) 25 dòng, ' || pg_temp.buffers(p) || ' buffers (< 100)') FROM pb;
SELECT pg_temp.ck(pg_temp.rows_out(p) = 4 AND pg_temp.buffers(p) < 100, '(c) 4 dòng, ' || pg_temp.buffers(p) || ' buffers (< 100)') FROM pc;
ROLLBACK;
