BEGIN;
:ans
;
CREATE FUNCTION pg_temp.am_of(p jsonb) RETURNS text LANGUAGE sql AS $$
  SELECT am.amname FROM pg_class c JOIN pg_am am ON am.oid = c.relam
  WHERE c.relname = (jsonb_path_query_first(p, '$.**."Index Name"') #>> '{}') LIMIT 1
$$;
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT id, name FROM products WHERE to_tsvector('simple', name) @@ plainto_tsquery('simple', 'Samsung phụ kiện E4DA')$$) AS p;
SELECT pg_temp.ck(pg_temp.rows_out(p) = 1, 'query trả 1 dòng') FROM p;
SELECT pg_temp.ck(pg_temp.am_of(p) IN ('gin', 'gist'), 'plan dùng index full-text (access method: ' || coalesce(pg_temp.am_of(p), 'không có') || ')') FROM p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 50, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 50; Seq Scan 398)') FROM p;
ROLLBACK;
