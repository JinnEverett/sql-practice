-- db: lab
-- reset
-- ordered
-- expect-rows: 2
-- Giải thích: created_at tăng theo thứ tự chèn → correlation 1.0 → Index Scan đọc heap gần như tuần tự, 13 buffers cho 1 093 dòng.
--   user_id = 1 + (i·7919 mod 20000) rải đều → correlation ≈ 0.001: 20 dòng của khách nằm ở 20 page khác nhau → Bitmap Heap Scan (sắp page trước khi đọc, mỗi page một lần).
-- Bẫy: nghĩ "ít dòng thì Index Scan, nhiều dòng thì Bitmap": thứ quyết định là selectivity VÀ correlation.
SELECT attname,
       round(abs(correlation)::numeric, 1) AS abs_corr,
       CASE attname WHEN 'created_at' THEN 'Index Scan' ELSE 'Bitmap Heap Scan' END AS node
FROM pg_stats
WHERE schemaname = 'p03' AND tablename = 'o' AND attname IN ('user_id', 'created_at')
ORDER BY attname;
