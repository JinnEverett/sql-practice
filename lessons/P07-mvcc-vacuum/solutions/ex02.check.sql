\o /dev/null
:ans
;
\o
SELECT pg_temp.ck((SELECT dead_tuple_count FROM pgstattuple('p07.bloat')) = 0, 'dead tuple = ' || (SELECT dead_tuple_count FROM pgstattuple('p07.bloat')) || ' (cần 0)');
SELECT pg_temp.ck(pg_relation_size('p07.bloat') / 8192 = 4545, 'số page vẫn ' || pg_relation_size('p07.bloat') / 8192 || ' (VACUUM thường không co file; VACUUM FULL sẽ đổi)');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM p07.bloat$$) = '100000', 'còn 100 000 dòng');
