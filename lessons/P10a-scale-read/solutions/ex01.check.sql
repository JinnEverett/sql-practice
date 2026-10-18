CREATE FUNCTION pg_temp.scan_of(q text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE p jsonb;
BEGIN
  p := pg_temp.plan(q, false);
  RETURN CASE WHEN pg_temp.has_node(p, 'Seq Scan', 't_m') THEN 'Seq Scan'
              WHEN pg_temp.has_node(p, 'Bitmap Heap Scan', 't_m') THEN 'Bitmap Heap Scan'
              WHEN pg_temp.has_node(p, 'Index Only Scan', 't_m') THEN 'Index Only Scan'
              WHEN pg_temp.has_node(p, 'Index Scan', 't_m') THEN 'Index Scan' ELSE '?' END;
END $$;
SELECT to_jsonb(t) AS expected FROM (SELECT
  pg_temp.scan_of($$SELECT id, amount FROM p10.t_m WHERE u < 10000$$) AS u_1pct,
  pg_temp.scan_of($$SELECT id, amount FROM p10.t_m WHERE u < 200000$$) AS u_20pct,
  pg_temp.scan_of($$SELECT id, amount FROM p10.t_m WHERE u < 900000$$) AS u_90pct,
  pg_temp.scan_of($$SELECT id, amount FROM p10.t_m WHERE ts < timestamptz '2025-01-01 00:00+00' + 300000 * interval '30 seconds'$$) AS ts_30pct,
  pg_temp.scan_of($$SELECT id, amount FROM p10.t_m WHERE ts < timestamptz '2025-01-01 00:00+00' + 950000 * interval '30 seconds'$$) AS ts_95pct) t \gset
SELECT pg_temp.ck(pg_temp.val(format('SELECT to_jsonb(t)::text FROM (%s) t', pg_temp.clean(:'ans'))) = (:'expected'::jsonb)::text, 'đáp án khớp plan thật: ' || :'expected');
