SET max_parallel_workers_per_gather = 0;
\o /dev/null
:ans
;
\o
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT * FROM p04.job WHERE kind = 'new'$$) AS p;
SELECT pg_temp.ck((p #>> '{Plan,Actual Rows}')::numeric = 100000, 'query thực tế trả 100 000 dòng') FROM p;
SELECT pg_temp.ck(greatest((p #>> '{Plan,Plan Rows}')::numeric, 100000) / least((p #>> '{Plan,Plan Rows}')::numeric, 100000) <= 3,
                  'ước lượng ' || (p #>> '{Plan,Plan Rows}') || ' vs thực tế 100000 (lệch ≤ 3×)') FROM p;
