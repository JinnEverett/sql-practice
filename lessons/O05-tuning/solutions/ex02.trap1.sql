-- Lời giải SAI: quên chi phí CPU cho mỗi dòng (cpu_tuple_cost), chỉ tính đọc trang.
SELECT c.relpages, c.reltuples::bigint AS reltuples,
       round(c.relpages * current_setting('seq_page_cost')::numeric, 2) AS seq_scan_cost
FROM pg_class c WHERE c.oid = 'o05.items'::regclass;
