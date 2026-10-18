-- db: lab
-- mode: check
-- reset
-- Giải thích: pg_stat_user_tables đếm theo bảng: seq_scan/idx_scan là số lần quét tuần tự/qua index; seq_tup_read là số dòng đọc bởi quét tuần tự.
--   Bảng LỚN mà quét tuần tự nhiều hơn quét index là ứng viên cho index hoặc cho việc viết lại truy vấn. Bảng nhỏ quét tuần tự là bình thường
--   (planner chọn đúng), nên lọc theo kích thước (pg_relation_size). idx_scan có thể NULL (bảng không có index) → coalesce.
--   Bộ đếm cộng dồn từ lần reset thống kê cuối; ANALYZE cũng có thể tính thêm vào seq_scan.
-- Bẫy: không lọc kích thước (bảng nhỏ lẫn vào); so sánh với idx_scan NULL cho kết quả NULL (dòng bị loại); sắp theo seq_scan thay vì seq_tup_read.
SELECT relname,
       seq_scan,
       coalesce(idx_scan, 0) AS idx_scan,
       seq_tup_read,
       pg_size_pretty(pg_relation_size(relid)) AS size
FROM pg_stat_user_tables
WHERE schemaname = 'o03'
  AND pg_relation_size(relid) > 10 * 1024 * 1024
  AND seq_scan > coalesce(idx_scan, 0)
ORDER BY seq_tup_read DESC;
