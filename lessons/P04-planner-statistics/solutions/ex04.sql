-- db: lab
-- mode: check
-- reset
-- Giải thích: MCV tối đa = statistics target của cột (mặc định 100). tag 180 xếp hạng ~150–200 nên không nằm trong MCV và bị ước lượng bằng
--   trung bình của phần còn lại (47 dòng; thực tế 137 = 2.9×). Tăng target của riêng cột tag lên 300–1000: MCV chứa tag 180, ước lượng ≈ 137.
--   Giá phải trả: ANALYZE đọc mẫu lớn hơn (300 × target dòng) và pg_statistic nặng hơn → chỉ tăng cho cột cần.
-- Bẫy: chỉ ANALYZE lại mà không đổi target (mẫu ngẫu nhiên, vẫn ~47); ALTER SYSTEM default_statistics_target (đổi cho cả server); quên ANALYZE sau SET STATISTICS.
ALTER TABLE p04.tag_event ALTER COLUMN tag SET STATISTICS 1000;
ANALYZE p04.tag_event;
