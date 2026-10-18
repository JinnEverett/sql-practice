SET max_parallel_workers_per_gather = 0;
BEGIN;
:ans
;
CREATE FUNCTION pg_temp.am_of(p jsonb) RETURNS text LANGUAGE sql AS $$
  SELECT am.amname FROM pg_class c JOIN pg_am am ON am.oid = c.relam
  WHERE c.relname = (jsonb_path_query_first(p, '$.**."Index Name"') #>> '{}') LIMIT 1
$$;
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT id FROM p05.booking WHERE during && tstzrange('2025-06-01 10:00+00', '2025-06-01 12:00+00')$$) AS p;
SELECT pg_temp.ck(pg_temp.rows_out(p) = 35, 'query trả 35 dòng') FROM p;
SELECT pg_temp.ck(pg_temp.am_of(p) = 'gist', 'plan dùng index GiST (access method: ' || coalesce(pg_temp.am_of(p), 'không có') || ')') FROM p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 50, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 50; Seq Scan 2 206)') FROM p;
ROLLBACK;
