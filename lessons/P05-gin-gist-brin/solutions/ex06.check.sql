SET max_parallel_workers_per_gather = 0;
CREATE TEMP TABLE q (n int, sql text);
INSERT INTO q VALUES
 (1, $$SELECT count(*) FROM p05.t WHERE user_id = 5$$),
 (2, $$SELECT sum(user_id) FROM p05.t WHERE status = 'delivered'$$),
 (3, $$SELECT sum(user_id) FROM p05.t WHERE flag$$),
 (4, $$SELECT count(*) FROM p05.t WHERE ts >= '2025-03-01' AND ts < '2025-03-02'$$),
 (5, $$SELECT count(*) FROM p05.t WHERE payload @> '{"sku": 77}'$$),
 (6, $$SELECT id FROM p05.t WHERE status = 'refunded'$$);
CREATE TEMP TABLE base AS SELECT n, pg_temp.plan(sql) AS p FROM q;
CREATE TEMP TABLE used0 AS SELECT DISTINCT x #>> '{}' AS idx FROM base, jsonb_path_query(p, '$.**."Index Name"') x;
BEGIN;
:ans
;
CREATE TEMP TABLE after AS SELECT n, pg_temp.plan(sql) AS p FROM q;
SELECT pg_temp.ck((SELECT coalesce(array_agg(c.relname::text ORDER BY c.relname), '{}') FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid WHERE i.indrelid = 'p05.t'::regclass AND NOT i.indisprimary)
                  = (SELECT coalesce(array_agg(idx ORDER BY idx) FILTER (WHERE idx <> 't_pkey'), '{}') FROM used0),
                  'index còn lại = index mà các truy vấn dùng: ' || (SELECT string_agg(c.relname, ', ' ORDER BY c.relname) FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid WHERE i.indrelid = 'p05.t'::regclass AND NOT i.indisprimary));
SELECT pg_temp.ck(pg_temp.buffers(a.p) <= 1.5 * pg_temp.buffers(b.p) + 50, 'truy vấn ' || a.n || ': ' || pg_temp.buffers(b.p) || ' → ' || pg_temp.buffers(a.p) || ' buffers') FROM after a JOIN base b USING (n) ORDER BY a.n;
ROLLBACK;
