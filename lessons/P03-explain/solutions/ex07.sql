-- db: lab
-- mode: check
-- reset
-- Giải thích: user_id không tương quan với vị trí vật lý → ngay cả 25% dòng planner vẫn thích Bitmap Heap Scan (đọc mỗi page một lần theo thứ tự) hơn Seq Scan;
--   chỉ khi lấy hơn nửa số dòng (giữa 50% và 55% theo đo thực tế) mới chuyển Seq Scan. created_at có correlation 1 nên Index Scan đọc heap tuần tự: tới khoảng 50–70% dòng mới thua Seq Scan.
--   Thêm tham số: đổi random_page_cost / effective_cache_size thì các điểm gãy này dịch chuyển; đó là lý do không đoán, mà EXPLAIN.
-- Bẫy: nghĩ "index luôn nhanh hơn khi có WHERE"; nghĩ "% dòng lớn → Seq Scan" bất kể correlation.
SELECT 'Bitmap Heap Scan' AS q1, 'Bitmap Heap Scan' AS q2, 'Seq Scan' AS q3, 'Index Scan' AS q4, 'Seq Scan' AS q5;
