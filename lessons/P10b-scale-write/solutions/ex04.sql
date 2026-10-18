-- db: lab
-- mode: check
-- reset
-- Giải thích: CREATE INDEX thường giữ ShareLock suốt lúc quét/sắp xếp (≈ 5.7 giây ở bảng này vì pg_sleep(0.5 ms) thực tế ~1 ms; 3.2 giây ở 10M dòng thật): mọi INSERT/UPDATE/DELETE bị chặn ngần ấy thời gian.
--   CREATE INDEX CONCURRENTLY chỉ giữ ShareUpdateExclusiveLock, quét bảng hai lần và chờ các transaction cũ kết thúc: ghi vẫn chạy, đổi lại build chậm hơn (đo: ×1.6–1.75; 3.2 → 5.1 giây ở 10M) và không chạy được trong transaction.
--   Nếu CONCURRENTLY lỗi giữa chừng nó để lại index INVALID (indisvalid = false) phải DROP rồi tạo lại.
-- Bẫy: CREATE INDEX thường ở production; CONCURRENTLY trong BEGIN … COMMIT (lỗi); quên kiểm tra indisvalid.
CREATE INDEX CONCURRENTLY t4_slow_idx ON p10b.t4 (p10b.slow_id(id));
