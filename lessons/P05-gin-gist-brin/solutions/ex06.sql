-- db: lab
-- mode: check
-- reset
-- Giải thích: plan của 6 truy vấn dùng: t_user_idx (1), t_ts_brin (4), t_payload_gin (5), t_status_idx (6: 'refunded' chỉ 1% → Bitmap Heap Scan). Truy vấn 2 (90%) và 3 (50%) Seq Scan
--   nên t_status_idx không giúp truy vấn 2 nhưng giữ vì truy vấn 6 cần; t_flag_idx (50/50) và t_name_trgm (không truy vấn nào ILIKE; 39 MB, bằng 72% kích thước bảng) không ai dùng.
--   Bỏ hai index đó: INSERT bớt 2 index phải cập nhật, bảng + index nhẹ đi ≈ 5 300 page.
-- Bẫy: bỏ cả t_status_idx vì "90% dòng là delivered" (truy vấn 6 hỏng); không dám bỏ t_name_trgm vì "biết đâu cần"; bỏ t_ts_brin vì nghĩ BRIN vô dụng.
DROP INDEX p05.t_flag_idx, p05.t_name_trgm;
