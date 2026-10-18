-- db: lab
-- mode: check
-- reset
-- Giải thích: VACUUM thường không giữ khóa chặn đọc/ghi (SHARE UPDATE EXCLUSIVE), thu hồi chỗ của tuple chết vào free space map và dọn entry index; file không co (4 545 page → 4 545 page),
--   free space nhảy từ 48% lên 75%. VACUUM FULL ghi lại cả bảng dưới ACCESS EXCLUSIVE và co file về 1 137 page → vi phạm yêu cầu "không khóa" (check thấy số page đổi).
-- Bẫy: VACUUM FULL cho tiện; chỉ ANALYZE (không dọn gì); chạy VACUUM trong transaction (không được).
VACUUM p07.bloat;
