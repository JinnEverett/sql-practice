-- db: lab
-- reset
-- expect-rows: 1
-- Giải thích: bảng có 100 000 dòng sống (mỗi dòng ~87 B kể cả header) cần ~1 137 page, nhưng file là 4 545 page: bloat 4×. tuple_percent = 22.3% là phần page do tuple SỐNG chiếm;
--   100 − 22.3 ≈ 78% là lãng phí: 22.3% tuple chết (thế hệ UPDATE cuối) + 48.1% chỗ trống đã được pruning giải phóng nhưng chưa trả file. Index cũng phình (825 page, sau VACUUM FULL còn 276).
-- Bẫy: chỉ nhìn dead_tuple_count (100 000, bằng số dòng sống) mà không thấy 48% free space; tính bloat theo n_dead_tup của pg_stat_user_tables (số đếm gần đúng, có thể trễ).
SELECT table_len / 8192 AS pages, tuple_count AS live, dead_tuple_count AS dead, round(100 - tuple_percent)::int AS wasted_pct
FROM pgstattuple('p07.bloat');
