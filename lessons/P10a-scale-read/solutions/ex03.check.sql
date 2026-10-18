CREATE FUNCTION pg_temp.join_of(q text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE p jsonb;
BEGIN
  p := pg_temp.plan(q, false);
  RETURN CASE WHEN pg_temp.has_node(p, 'Nested Loop') THEN 'Nested Loop' WHEN pg_temp.has_node(p, 'Hash Join') THEN 'Hash Join'
              WHEN pg_temp.has_node(p, 'Merge Join') THEN 'Merge Join' ELSE '?' END;
END $$;
SELECT to_jsonb(t) AS expected FROM (SELECT
  pg_temp.join_of($$SELECT count(*) FROM p10.t_m a JOIN p10.mid b ON b.id = a.amount + 1 WHERE a.u < 100$$) AS k100,
  pg_temp.join_of($$SELECT count(*) FROM p10.t_m a JOIN p10.mid b ON b.id = a.amount + 1 WHERE a.u < 1000$$) AS k1000,
  pg_temp.join_of($$SELECT count(*) FROM p10.t_m a JOIN p10.mid b ON b.id = a.amount + 1 WHERE a.u < 100000$$) AS k100000,
  pg_temp.join_of($$SELECT count(*) FROM p10.t_m a JOIN p10.mid b ON b.id = a.amount + 1 WHERE a.u < 900000$$) AS k900000) t \gset
SELECT pg_temp.ck(pg_temp.val(format('SELECT to_jsonb(t)::text FROM (%s) t', pg_temp.clean(:'ans'))) = (:'expected'::jsonb)::text, 'đáp án khớp plan thật: ' || :'expected');
