SELECT split_part(:'ans', '-- query', 2) AS q \gset
SELECT pg_temp.ck(pg_temp.same(:'q', $ref$SELECT id, title FROM p09.docs WHERE kind = 'long'$ref$), 'trả đúng id, title của 300 tài liệu long');
CREATE FUNCTION pg_temp.ser(q text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE r json;
BEGIN EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, SERIALIZE, FORMAT JSON) ' || pg_temp.clean(q) INTO r; RETURN (r::jsonb) -> 0; END $$;
CREATE TEMP TABLE s AS SELECT pg_temp.ser(:'q') AS j;
SELECT pg_temp.ck((j #>> '{Serialization,Output Volume}')::bigint < 100, 'dữ liệu gửi về client ' || (j #>> '{Serialization,Output Volume}') || ' kB (< 100 kB; SELECT * là 17 823 kB)') FROM s;
SELECT pg_temp.ck(pg_temp.buffers(j) + (j #>> '{Serialization,Shared Hit Blocks}')::bigint + (j #>> '{Serialization,Shared Read Blocks}')::bigint < 200,
                  'tổng buffers kể cả serialize: ' || (pg_temp.buffers(j) + (j #>> '{Serialization,Shared Hit Blocks}')::bigint + (j #>> '{Serialization,Shared Read Blocks}')::bigint) || ' (< 200)') FROM s;
