BEGIN;
:ans
;
CREATE FUNCTION pg_temp.am_of(p jsonb) RETURNS text LANGUAGE sql AS $$
  SELECT am.amname FROM pg_class c JOIN pg_am am ON am.oid = c.relam
  WHERE c.relname = (jsonb_path_query_first(p, '$.**."Index Name"') #>> '{}') LIMIT 1
$$;
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT count(*) FROM events WHERE created_at >= '2026-09-29' AND created_at < '2026-09-30'$$) AS p;
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM events WHERE created_at >= '2026-09-29' AND created_at < '2026-09-30'$$) = '18166', 'query đếm đúng 18 166 sự kiện');
SELECT pg_temp.ck(pg_temp.am_of(p) = 'brin', 'plan dùng index BRIN (access method: ' || coalesce(pg_temp.am_of(p), 'không có') || ')') FROM p;
SELECT pg_temp.ck(pg_temp.buffers(p) < 1500, 'đọc ' || pg_temp.buffers(p) || ' buffers (< 1 500; Seq Scan ~45 000)') FROM p;
SELECT pg_temp.ck((SELECT coalesce(sum(pg_relation_size(i.indexrelid)), 0) FROM pg_index i WHERE i.indrelid = 'public.events'::regclass AND i.indexrelid <> 'public.events_pkey'::regclass) BETWEEN 1 AND 1048576,
                  'index mới tổng ' || (SELECT round(coalesce(sum(pg_relation_size(i.indexrelid)), 0) / 1024.0) FROM pg_index i WHERE i.indrelid = 'public.events'::regclass AND i.indexrelid <> 'public.events_pkey'::regclass) || ' kB (≤ 1 MB)');
ROLLBACK;
