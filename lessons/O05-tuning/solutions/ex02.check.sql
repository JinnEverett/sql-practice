SELECT format('CREATE TEMP VIEW ans_v AS %s', pg_temp.clean(:'ans')) \gexec
SELECT pg_temp.ck((SELECT string_agg(column_name, ',' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_name = 'ans_v' AND table_schema LIKE 'pg_temp%') = 'relpages,reltuples,seq_scan_cost', 'cột relpages, reltuples, seq_scan_cost');
SELECT pg_temp.ck((SELECT count(*) FROM ans_v) = 1, 'đúng 1 dòng');
-- cost thật mà planner gán cho Seq Scan (không chạy truy vấn, chỉ EXPLAIN)
CREATE TEMP TABLE real_plan AS SELECT pg_temp.plan('SELECT * FROM o05.items', false) AS p;
SELECT pg_temp.ck((SELECT p -> 'Plan' ->> 'Node Type' FROM real_plan) = 'Seq Scan', 'plan thật là Seq Scan');
SELECT pg_temp.ck((SELECT seq_scan_cost FROM ans_v) = round((SELECT (p -> 'Plan' ->> 'Total Cost')::numeric FROM real_plan), 2),
  'seq_scan_cost = ' || (SELECT seq_scan_cost FROM ans_v) || ', cost trong EXPLAIN = ' || (SELECT round((p -> 'Plan' ->> 'Total Cost')::numeric, 2) FROM real_plan));
SELECT pg_temp.ck((SELECT relpages FROM ans_v) = (SELECT relpages FROM pg_class WHERE oid = 'o05.items'::regclass), 'relpages khớp pg_class');
SELECT pg_temp.ck((SELECT reltuples FROM ans_v) = 200000, 'reltuples = 200000');
