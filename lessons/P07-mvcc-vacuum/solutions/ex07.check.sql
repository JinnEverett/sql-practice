\o /dev/null
:ans
;
\o
CREATE TEMP TABLE o AS SELECT coalesce(reloptions, '{}') AS r FROM pg_class WHERE oid = 'p07.queue'::regclass;
SELECT pg_temp.ck(NOT ('autovacuum_enabled=false' = ANY (r)), 'autovacuum bật cho bảng') FROM o;
CREATE TEMP TABLE trig AS
SELECT coalesce((SELECT split_part(x, '=', 2)::numeric FROM o, unnest(r) x WHERE x LIKE 'autovacuum_vacuum_threshold=%'), 50)
     + coalesce((SELECT split_part(x, '=', 2)::numeric FROM o, unnest(r) x WHERE x LIKE 'autovacuum_vacuum_scale_factor=%'), 0.2) * 20000000 AS dead_needed;
SELECT pg_temp.ck(dead_needed <= 150000, 'với 20M dòng: autovacuum chạy khi có ' || round(dead_needed) || ' dead tuple (≤ 150 000)') FROM trig;
SELECT pg_temp.ck(current_setting('autovacuum_vacuum_scale_factor') = '0.2', 'không đổi cấu hình toàn server');
