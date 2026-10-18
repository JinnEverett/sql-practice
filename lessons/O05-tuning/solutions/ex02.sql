-- db: lab
-- mode: check
-- reset
-- Giải thích: planner không đo thời gian mà cộng điểm cost từ thống kê (pg_class.relpages, reltuples) và các hằng số cost.
--   Seq Scan không lọc: cost = relpages × seq_page_cost + reltuples × cpu_tuple_cost. Đổi seq_page_cost hay cpu_tuple_cost là đổi cost của MỌI
--   Seq Scan, và vì thế đổi lúc nào planner thấy Seq Scan "rẻ hơn" index. Thống kê cũ (chưa ANALYZE) làm con số này lệch khỏi thực tế.
-- Bẫy: thêm random_page_cost (chỉ áp cho đọc ngẫu nhiên, không phải Seq Scan); quên cpu_tuple_cost; reltuples là real: nhân với numeric ra double precision và round(double, int) không tồn tại, nên ép reltuples::numeric.
SELECT c.relpages,
       c.reltuples::bigint AS reltuples,
       round(c.relpages * current_setting('seq_page_cost')::numeric
           + c.reltuples::numeric * current_setting('cpu_tuple_cost')::numeric, 2) AS seq_scan_cost
FROM pg_class c
WHERE c.oid = 'o05.items'::regclass;
