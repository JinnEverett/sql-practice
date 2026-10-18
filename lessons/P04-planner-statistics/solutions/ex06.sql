-- db: lab
-- mode: check
-- reset
-- Giải thích: histogram dừng ở 2026-09-30 nên `created_at >= '2026-10-01'` rơi ngoài histogram → planner ước lượng rất nhỏ (568 thay vì 20 000, 35×).
--   ANALYZE ngay thì khắc phục tức thì. Dài hạn: autovacuum ANALYZE khi đổi > 50 + 0.1 × 220 000 = 22 050 dòng, mà job đêm chỉ thêm 20 000 → không bao giờ chạm ngưỡng.
--   Hạ scale_factor còn 0.01 (50 + 2 200 = 2 250 dòng) và nhớ bật lại autovacuum_enabled (bảng bài tập đang tắt).
-- Bẫy: chỉ ANALYZE tay (mai lại hỏng); chỉ đổi reloption mà không ANALYZE ngay (hôm nay vẫn tồi); đặt scale_factor cho cả server.
ANALYZE p04.log;
ALTER TABLE p04.log SET (autovacuum_enabled = true, autovacuum_analyze_scale_factor = 0.01);
