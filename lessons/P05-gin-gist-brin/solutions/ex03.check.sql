BEGIN;
:ans
;
CREATE FUNCTION pg_temp.am_of(p jsonb) RETURNS text LANGUAGE sql AS $$
  SELECT am.amname FROM pg_class c JOIN pg_am am ON am.oid = c.relam
  WHERE c.relname = (jsonb_path_query_first(p, '$.**."Index Name"') #>> '{}') LIMIT 1
$$;
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT id, email FROM users WHERE email ILIKE '%hung.pham88%'$$) AS p;
SELECT pg_temp.ck(pg_temp.rows_out(p) = 4, 'query trả 4 dòng') FROM p;
SELECT pg_temp.ck(pg_temp.am_of(p) IN ('gin', 'gist') AND NOT pg_temp.has_node(p, 'Seq Scan'), 'plan dùng index ' || coalesce(pg_temp.am_of(p), 'không có') || ', không Seq Scan') FROM p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 600, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 600; Seq Scan 1 526)') FROM p;
ROLLBACK;
