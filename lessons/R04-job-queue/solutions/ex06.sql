-- db: lab
-- mode: check
-- reset
-- Giải thích: cùng câu nhận job, nhưng lần này 3 worker chạy song song vòng lặp "nhận → xử lý → đánh dấu done" cho tới khi hết job.
--   Điều cần đúng: mỗi job được xử lý đúng MỘT lần (không trùng, không sót) dù 3 worker tranh nhau.
--   Câu trả lời của bạn là câu NHẬN một job (UPDATE … RETURNING id). Bộ chấm viết phần còn lại (vòng lặp, ghi log, đánh dấu done).
-- Bẫy: không khóa → trùng job hoặc worker thấy NULL sớm rồi thoát khi vẫn còn job; WHERE thiếu status = 'queued' → nhận lại job đã xong.
UPDATE r04.jobs
SET status = 'running', attempts = attempts + 1, locked_at = now(), locked_by = 'worker-1'
WHERE id = (SELECT id FROM r04.jobs
            WHERE status = 'queued' AND run_at <= now()
            ORDER BY priority DESC, run_at, id
            LIMIT 1
            FOR UPDATE SKIP LOCKED)
RETURNING id;
