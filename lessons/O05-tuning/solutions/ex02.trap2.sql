-- Lời giải SAI: dùng random_page_cost cho Seq Scan (nhầm giữa đọc tuần tự và đọc ngẫu nhiên).
SELECT c.relpages, c.reltuples::bigint AS reltuples,
       round(c.relpages * current_setting('random_page_cost')::numeric
           + c.reltuples::numeric * current_setting('cpu_tuple_cost')::numeric, 2) AS seq_scan_cost
FROM pg_class c WHERE c.oid = 'o05.items'::regclass;
