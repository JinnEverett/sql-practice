-- sai: có FOR UPDATE nhưng thiếu SKIP LOCKED → session B chờ khóa của A (quá lock_timeout)
UPDATE r04.jobs
SET status = 'running', attempts = attempts + 1, locked_at = now(), locked_by = 'worker-1'
WHERE id = (SELECT id FROM r04.jobs WHERE status = 'queued' AND run_at <= now() ORDER BY priority DESC, run_at, id LIMIT 1 FOR UPDATE)
RETURNING id;
