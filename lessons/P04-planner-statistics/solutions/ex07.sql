-- db: lab
-- mode: check
-- reset
-- Giải thích: số nhóm ước lượng = n_distinct(a) × n_distinct(b) = 1 000 × 1 000, chặn trên bởi ~số dòng → 20 000 (thực tế 1 000 vì b = a). HashAggregate dự trù RAM theo ước lượng (601 kB vs 121 kB sau khi sửa).
--   Với bảng lớn hơn, ước lượng phình theo → planner bỏ HashAggregate chọn Sort + GroupAggregate hoặc spill. ndistinct statistics lưu số giá trị khác nhau của tổ hợp (a, b).
-- Bẫy: ANALYZE lại mà không CREATE STATISTICS; dependencies (không giúp số nhóm); quên ANALYZE sau CREATE STATISTICS.
CREATE STATISTICS fact_nd (ndistinct) ON a, b FROM p04.fact;
ANALYZE p04.fact;
