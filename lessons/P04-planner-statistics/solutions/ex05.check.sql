SET max_parallel_workers_per_gather = 0;
\o /dev/null
:ans
;
\o
CREATE TEMP TABLE p AS SELECT pg_temp.plan($$SELECT * FROM p04.addr WHERE city = 7 AND zip = 71$$) AS p;
SELECT pg_temp.ck((p #>> '{Plan,Actual Rows}')::numeric = 1000, 'thực tế 1 000 dòng') FROM p;
SELECT pg_temp.ck(greatest((p #>> '{Plan,Plan Rows}')::numeric, 1000) / least((p #>> '{Plan,Plan Rows}')::numeric, 1000) <= 2,
                  'ước lượng ' || (p #>> '{Plan,Plan Rows}') || ' vs thực tế 1000 (lệch ≤ 2×)') FROM p;
