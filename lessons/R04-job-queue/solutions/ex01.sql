-- db: lab
-- mode: state
-- show-output
-- Giải thích: nhận MỘT job = chọn job đủ điều kiện rồi đánh dấu 'running' trong CÙNG một câu lệnh.
--   Chọn: status = 'queued' AND run_at <= now(), ưu tiên priority giảm dần rồi run_at tăng dần rồi id (thứ tự xác định).
--   FOR UPDATE SKIP LOCKED: khóa dòng được chọn và BỎ QUA dòng đang bị worker khác khóa, thay vì chờ → nhiều worker không giẫm chân nhau.
--   attempts + 1 ngay lúc nhận (kể cả nếu worker chết giữa chừng thì lượt thử vẫn được tính).
-- Bẫy: thiếu SKIP LOCKED → các worker xếp hàng chờ nhau; thiếu FOR UPDATE → hai worker chọn cùng job; quên run_at <= now() → nhận cả job hẹn giờ (job 4).
UPDATE r04.jobs
SET status = 'running', attempts = attempts + 1, locked_at = now(), locked_by = 'worker-1'
WHERE id = (SELECT id FROM r04.jobs
            WHERE status = 'queued' AND run_at <= now()
            ORDER BY priority DESC, run_at, id
            LIMIT 1
            FOR UPDATE SKIP LOCKED)
RETURNING id;
