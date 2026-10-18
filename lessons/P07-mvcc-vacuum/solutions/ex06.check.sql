\o /dev/null
:ans
;
\o
SELECT pg_temp.ck((SELECT all_frozen FROM pg_visibility_map_summary('p07.hist')) = pg_relation_size('p07.hist') / 8192,
                  'all_frozen ' || (SELECT all_frozen FROM pg_visibility_map_summary('p07.hist')) || ' / ' || pg_relation_size('p07.hist') / 8192 || ' page');
SELECT pg_temp.ck((SELECT age(relfrozenxid)::bigint FROM pg_class WHERE oid = 'p07.hist'::regclass) < 1000, 'age(relfrozenxid) = ' || (SELECT age(relfrozenxid)::bigint FROM pg_class WHERE oid = 'p07.hist'::regclass) || ' (< 1 000)');
