-- db: lab
-- mode: check
-- reset
-- Giải thích: ngưỡng = autovacuum_vacuum_threshold + autovacuum_vacuum_scale_factor × reltuples. Mặc định 50 + 0.2 × 20M = 4 000 050 dead tuple (hàng đợi đã phình rất lâu trước đó).
--   Với scale_factor 0.005 và threshold 1 000: 1 000 + 0.005 × 20M = 101 000 ≤ 150 000. Đặt per-table để các bảng khác không bị ảnh hưởng. Bảng bài tập đang tắt autovacuum nên phải bật lại.
-- Bẫy: chỉ hạ scale_factor mà quên bật autovacuum_enabled; đổi toàn server (ALTER SYSTEM) làm mọi bảng vacuum dày; chỉ hạ threshold (vô nghĩa với bảng lớn).
ALTER TABLE p07.queue SET (autovacuum_enabled = true, autovacuum_vacuum_scale_factor = 0.005, autovacuum_vacuum_threshold = 1000);
