BEGIN;
:ans
;
SELECT pg_temp.ck((SELECT count(*) FROM pg_index WHERE indrelid = 'p02.ord'::regclass AND NOT indisprimary) <= 2, 'còn ≤ 2 index ngoài PK (hiện ' || (SELECT count(*) FROM pg_index WHERE indrelid = 'p02.ord'::regclass AND NOT indisprimary) || ')');
CREATE TEMP TABLE p1 AS SELECT pg_temp.plan($$SELECT id FROM p02.ord WHERE user_id = 777$$) AS p;
CREATE TEMP TABLE p2 AS SELECT pg_temp.plan($$SELECT id FROM p02.ord WHERE user_id = 777 ORDER BY created_at DESC LIMIT 3$$) AS p;
CREATE TEMP TABLE p3 AS SELECT pg_temp.plan($$SELECT id FROM p02.ord WHERE user_id = 777 AND created_at >= '2025-06-01' AND status = 'delivered'$$) AS p;
CREATE TEMP TABLE p4 AS SELECT pg_temp.plan($$SELECT id FROM p02.ord WHERE status = 'pending'$$) AS p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 100, 'query 1: ' || pg_temp.buffers(p) || ' buffers (< 100)') FROM p1;
SELECT pg_temp.ck(pg_temp.buffers(p) < 100, 'query 2: ' || pg_temp.buffers(p) || ' buffers (< 100)') FROM p2;
SELECT pg_temp.ck(pg_temp.buffers(p) < 100, 'query 3: ' || pg_temp.buffers(p) || ' buffers (< 100)') FROM p3;
SELECT pg_temp.ck(pg_temp.buffers(p) < 600 AND pg_temp.rows_out(p) = 297, 'query 4: ' || pg_temp.buffers(p) || ' buffers (< 600), 297 dòng') FROM p4;
ROLLBACK;
