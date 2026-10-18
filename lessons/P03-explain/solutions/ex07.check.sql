CREATE FUNCTION pg_temp.scan_of(q text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE p jsonb;
BEGIN
  p := pg_temp.plan(q, false);
  RETURN CASE WHEN pg_temp.has_node(p, 'Seq Scan', 'o') THEN 'Seq Scan'
              WHEN pg_temp.has_node(p, 'Bitmap Heap Scan', 'o') THEN 'Bitmap Heap Scan'
              WHEN pg_temp.has_node(p, 'Index Only Scan', 'o') THEN 'Index Only Scan'
              WHEN pg_temp.has_node(p, 'Index Scan', 'o') THEN 'Index Scan' ELSE '?' END;
END $$;
SELECT to_jsonb(t) AS expected FROM (SELECT
  pg_temp.scan_of($$SELECT id, amount FROM p03.o WHERE user_id < 60$$) AS q1,
  pg_temp.scan_of($$SELECT id, amount FROM p03.o WHERE user_id < 5000$$) AS q2,
  pg_temp.scan_of($$SELECT id, amount FROM p03.o WHERE user_id < 20000$$) AS q3,
  pg_temp.scan_of($$SELECT id, amount FROM p03.o WHERE created_at < '2025-03-15'$$) AS q4,
  pg_temp.scan_of($$SELECT id, amount FROM p03.o WHERE created_at < '2025-11-26'$$) AS q5) t \gset
SELECT pg_temp.ck(pg_temp.val(format('SELECT to_jsonb(t)::text FROM (%s) t', pg_temp.clean(:'ans'))) = (:'expected'::jsonb)::text,
                  'đáp án khớp plan thật: ' || :'expected');
