-- sai: đo bằng run_at (job 5 và 9 có run_at cũ 30 phút) → reclaim oan hai job vừa mới được nhận
UPDATE r04.jobs
SET status = CASE WHEN attempts >= max_attempts THEN 'dead' ELSE 'queued' END, locked_at = NULL, locked_by = NULL, last_error = 'reclaimed: worker timeout'
WHERE status = 'running' AND run_at < now() - interval '5 minutes';
