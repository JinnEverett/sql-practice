-- db: lab
-- mode: check
-- reset
-- Giải thích: chỉ lệnh ghi lại bảng sang file mới mới co được file: VACUUM FULL (4 545 → 1 137 page; index val 825 → 276) hoặc CLUSTER (cũng rewrite, kèm sắp lại theo index).
--   Cả hai giữ ACCESS EXCLUSIVE suốt thời gian chạy và cần chỗ trống cho bản sao. Ở production dùng pg_repack hoặc partition + DROP để tránh khóa.
-- Bẫy: VACUUM thường (free 75% nhưng file nguyên); REINDEX (chỉ index co); ALTER TABLE SET fillfactor (chỉ áp dụng cho page mới).
VACUUM FULL p07.bloat;
