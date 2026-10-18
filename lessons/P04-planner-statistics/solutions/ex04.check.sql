SET max_parallel_workers_per_gather = 0;
\o /dev/null
:ans
;
\o
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT * FROM p04.tag_event WHERE tag = 180$$) AS p;
SELECT pg_temp.ck((p #>> '{Plan,Actual Rows}')::numeric = 137, 'thực tế 137 dòng') FROM p;
SELECT pg_temp.ck(greatest((p #>> '{Plan,Plan Rows}')::numeric, 137) / least((p #>> '{Plan,Plan Rows}')::numeric, 137) <= 1.5,
                  'ước lượng ' || (p #>> '{Plan,Plan Rows}') || ' vs thực tế 137 (lệch ≤ 1.5×)') FROM p;
SELECT pg_temp.ck(current_setting('default_statistics_target') = '100', 'default_statistics_target vẫn 100 (không đổi cấu hình chung)');
