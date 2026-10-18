-- sai: backoff cố định 10 giây (không tăng theo số lần thử)
UPDATE r04.jobs
SET status = CASE WHEN attempts >= max_attempts THEN 'dead' ELSE 'queued' END,
    run_at = CASE WHEN attempts >= max_attempts THEN run_at ELSE now() + interval '10 seconds' END,
    locked_at = NULL, locked_by = NULL, last_error = 'timeout'
WHERE id IN (5, 9) AND status = 'running';
