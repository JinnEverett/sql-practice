-- db: lab
-- mode: check
-- reset
-- Giải thích: pg_try_advisory_lock(42) không chờ: trả false ngay nếu session khác (bản chạy trước của job) đang giữ khóa 42, nên lệnh INSERT bị WHERE lọc → job lần này bỏ qua.
--   Khi khóa rảnh trả true và chạy. Khóa advisory là khóa theo ứng dụng, không gắn với bảng/dòng; mức session giữ tới khi disconnect hoặc pg_advisory_unlock.
-- Bẫy: pg_advisory_lock (chờ vô hạn → chồng job); đặt sai khóa (43); quên rằng khóa session còn giữ khi script kết thúc (dùng pg_try_advisory_xact_lock trong BEGIN…COMMIT nếu muốn tự nhả).
INSERT INTO p08.runs SELECT 'ran' WHERE pg_try_advisory_lock(42);
