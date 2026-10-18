BEGIN;
:ans
;
CREATE FUNCTION pg_temp.am_of(p jsonb) RETURNS text LANGUAGE sql AS $$
  SELECT am.amname FROM pg_class c JOIN pg_am am ON am.oid = c.relam
  WHERE c.relname = (jsonb_path_query_first(p, '$.**."Index Name"') #>> '{}') LIMIT 1
$$;
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT count(*) FROM events WHERE properties @> '{"product_id": 12345}'$$) AS p;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM events WHERE properties @> '{"product_id": 12345}'$$) = '40', 'query đếm đúng 40 sự kiện');
SELECT pg_temp.ck(pg_temp.am_of(p) = 'gin', 'plan dùng index GIN (access method: ' || coalesce(pg_temp.am_of(p), 'không có') || ')') FROM p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 200, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 200; Seq Scan ~45 000)') FROM p;
ROLLBACK;
