SET max_parallel_workers_per_gather = 0;
\o /dev/null
:ans
;
\o
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT * FROM p04.log WHERE created_at >= '2026-10-01'$$) AS p;
SELECT pg_temp.ck((p #>> '{Plan,Actual Rows}')::numeric = 20000, 'thực tế 20 000 dòng') FROM p;
SELECT pg_temp.ck(greatest((p #>> '{Plan,Plan Rows}')::numeric, 20000) / least((p #>> '{Plan,Plan Rows}')::numeric, 20000) <= 3,
                  'ước lượng ' || (p #>> '{Plan,Plan Rows}') || ' vs thực tế 20000 (lệch ≤ 3×)') FROM p;
CREATE TEMP TABLE o AS SELECT coalesce(reloptions, '{}') AS r FROM pg_class WHERE oid = 'p04.log'::regclass;
SELECT pg_temp.ck(NOT ('autovacuum_enabled=false' = ANY (r)), 'autovacuum đã bật lại cho bảng') FROM o;
SELECT pg_temp.ck(coalesce((SELECT split_part(x, '=', 2)::numeric FROM o, unnest(r) x WHERE x LIKE 'autovacuum_analyze_scale_factor=%'), 0.1)
                  * 220000 + coalesce((SELECT split_part(x, '=', 2)::numeric FROM o, unnest(r) x WHERE x LIKE 'autovacuum_analyze_threshold=%'), 50) <= 0.011 * 220000 + 1000,
                  'ngưỡng autovacuum ANALYZE ≤ ~1% bảng (≈ ' || round(coalesce((SELECT split_part(x, '=', 2)::numeric FROM o, unnest(r) x WHERE x LIKE 'autovacuum_analyze_scale_factor=%'), 0.1) * 220000
                  + coalesce((SELECT split_part(x, '=', 2)::numeric FROM o, unnest(r) x WHERE x LIKE 'autovacuum_analyze_threshold=%'), 50)) || ' dòng đổi)');
