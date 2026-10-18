SET max_parallel_workers_per_gather = 0;
SELECT pg_temp.val(:'ans')::int AS mb \gset
SELECT floor(0.8 * :mb)::int AS mb80 \gset
CREATE FUNCTION pg_temp.spill(mb int) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE p jsonb;
BEGIN
  EXECUTE format('SET work_mem = ''%sMB''', mb);
  p := pg_temp.plan($q$SELECT count(*) FROM (SELECT id FROM p10.t_m ORDER BY amount, id) s$q$);
  RESET work_mem;
  RETURN pg_temp.temp_written(p);
END $$;
SELECT pg_temp.ck(pg_temp.spill(:mb) = 0, 'ở ' || :mb || ' MB: không ghi file tạm');
SELECT pg_temp.ck(pg_temp.spill(:mb80) > 0, 'ở ' || :mb80 || ' MB (80%): có ghi file tạm → ' || :mb || ' MB là sát ngưỡng');
