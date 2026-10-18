-- db: lab
-- mode: state
-- Giải thích: worker chết giữa chừng thì job kẹt ở 'running' mãi. Cơ chế "visibility timeout": job running quá 5 phút kể từ locked_at coi như treo.
--   Job treo còn lượt thử → trả về 'queued' (nhả khóa); đã hết lượt thử (attempts >= max_attempts) → 'dead'.
--   Job 5 (nhận 1 phút trước) và job 9 (2 phút trước) chưa treo nên KHÔNG đụng tới.
-- Bẫy: dùng created/run_at thay vì locked_at để đo thời gian treo (job chờ lâu rồi mới được nhận sẽ bị reclaim oan); quên điều kiện status = 'running'.
UPDATE r04.jobs
SET status    = CASE WHEN attempts >= max_attempts THEN 'dead' ELSE 'queued' END,
    locked_at = NULL,
    locked_by = NULL,
    last_error = 'reclaimed: worker timeout'
WHERE status = 'running' AND locked_at < now() - interval '5 minutes';
