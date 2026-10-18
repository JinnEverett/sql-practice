-- sai: quên run_at <= now() → nhận được cả job hẹn giờ tương lai (job 4, ưu tiên 9)
UPDATE r04.jobs
SET status = 'running', attempts = attempts + 1, locked_at = now(), locked_by = 'worker-1'
WHERE id = (SELECT id FROM r04.jobs WHERE status = 'queued' ORDER BY priority DESC, run_at, id LIMIT 1 FOR UPDATE SKIP LOCKED)
RETURNING id;
