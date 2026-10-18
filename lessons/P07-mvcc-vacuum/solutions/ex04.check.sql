\o /dev/null
:ans
;
\o
SELECT pg_temp.ck(pg_relation_size('p07.bloat') / 8192 <= 1818, 'heap còn ' || pg_relation_size('p07.bloat') / 8192 || ' page (≤ 1 818; trước đó 4 545)');
SELECT pg_temp.ck(pg_temp.val($$SELECT count(*) FROM p07.bloat$$) = '100000', 'còn 100 000 dòng');
SELECT pg_temp.ck(to_regclass('p07.bloat_val_idx') IS NOT NULL, 'index bloat_val_idx còn nguyên');
