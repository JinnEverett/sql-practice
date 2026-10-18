-- db: lab
-- mode: check
-- reset
-- Giải thích: `u` đều và không tương quan với vị trí vật lý → mỗi dòng khớp nằm ở một page khác; planner dùng Bitmap Heap Scan (sắp page, đọc mỗi page một lần) cho 1% và 20%, chỉ chuyển Seq Scan khi lấy khoảng 45–50% bảng.
--   `ts` tăng theo thứ tự chèn (correlation 1) → Index Scan đọc heap tuần tự, thắng Seq Scan tới khoảng 60–65%; 95% thì quét tuần tự rẻ hơn.
-- Bẫy: "ít dòng thì Index Scan, nhiều dòng thì Seq Scan" bỏ qua correlation; nghĩ Bitmap chỉ dành cho OR.
SELECT 'Bitmap Heap Scan' AS u_1pct, 'Bitmap Heap Scan' AS u_20pct, 'Seq Scan' AS u_90pct, 'Index Scan' AS ts_30pct, 'Seq Scan' AS ts_95pct;
