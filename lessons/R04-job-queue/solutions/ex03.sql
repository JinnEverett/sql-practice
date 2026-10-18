-- db: lab
-- mode: state
-- Giải thích: worker báo thất bại ('timeout') cho job 5 (đã thử 1/3) và job 9 (đã thử 3/3). Một câu UPDATE xử lý cả hai nhánh bằng CASE:
--   còn lượt thử → quay lại 'queued', hẹn giờ chạy lại với exponential backoff run_at = now() + 10 giây × 2^attempts (lần 1 → 20 giây);
--   hết lượt thử → 'dead' (dead-letter: giữ lại để người xem xét, không thử nữa).
--   Cả hai nhánh nhả khóa (locked_at, locked_by = NULL) và ghi last_error.
-- Bẫy: cộng attempts lần nữa (đã cộng lúc nhận job); backoff cố định làm mọi job lỗi cùng thử lại một lúc (thundering herd) → thêm jitter ngẫu nhiên ở bản thật.
UPDATE r04.jobs
SET status     = CASE WHEN attempts >= max_attempts THEN 'dead' ELSE 'queued' END,
    run_at     = CASE WHEN attempts >= max_attempts THEN run_at ELSE now() + interval '10 seconds' * power(2, attempts) END,
    locked_at  = NULL,
    locked_by  = NULL,
    last_error = 'timeout'
WHERE id IN (5, 9) AND status = 'running';
