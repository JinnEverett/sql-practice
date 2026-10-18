-- db: lab
-- mode: check
-- reset
-- Giải thích: câu nhận job (ex01) viết lại thành MỘT câu UPDATE … RETURNING id. Bộ chấm cho hai session chạy nó gần như cùng lúc:
--   session A nhận job rồi giữ transaction mở 1.5 giây; session B (lock_timeout 300ms) phải nhận được JOB KHÁC ngay, không chờ khóa.
--   Chỉ SKIP LOCKED làm được điều đó: FOR UPDATE thường sẽ chờ A (quá 300ms → lỗi), còn bỏ khóa thì B chọn trúng chính job của A.
-- Bẫy: thiếu FOR UPDATE (cả hai chọn cùng một job); FOR UPDATE nhưng thiếu SKIP LOCKED (B bị chặn).
UPDATE r04.jobs
SET status = 'running', attempts = attempts + 1, locked_at = now(), locked_by = 'worker-1'
WHERE id = (SELECT id FROM r04.jobs
            WHERE status = 'queued' AND run_at <= now()
            ORDER BY priority DESC, run_at, id
            LIMIT 1
            FOR UPDATE SKIP LOCKED)
RETURNING id;
