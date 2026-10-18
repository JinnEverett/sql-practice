-- db: lab
-- mode: check
-- reset
-- Giải thích: ADD CONSTRAINT CHECK trần phải quét cả bảng để kiểm tra dữ liệu cũ KHI đang giữ ACCESS EXCLUSIVE (chặn cả SELECT): ≈ 5.7 giây ở bảng này; đo thật: 78 ms ở 1M dòng, 616 ms ở 10M (hàm rẻ), lâu hơn nhiều nếu biểu thức đắt.
--   Cách chia đôi: ... NOT VALID (không quét, khóa rất ngắn, ràng buộc áp dụng ngay cho dòng MỚI) rồi VALIDATE CONSTRAINT (quét dữ liệu cũ với ShareUpdateExclusiveLock: ghi vẫn chạy). Cùng mẫu cho FOREIGN KEY và SET NOT NULL (qua CHECK … NOT VALID rồi VALIDATE rồi SET NOT NULL, Postgres 12+ bỏ qua bước quét).
-- Bẫy: ADD CONSTRAINT trần trên bảng lớn; quên VALIDATE (ràng buộc còn NOT VALID mãi: planner không dùng để tối ưu).
ALTER TABLE p10b.t7 ADD CONSTRAINT t7_ck CHECK (p10b.slow_ok(id)) NOT VALID;
ALTER TABLE p10b.t7 VALIDATE CONSTRAINT t7_ck;
