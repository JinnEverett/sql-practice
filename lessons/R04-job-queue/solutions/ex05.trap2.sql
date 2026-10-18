-- sai: không khóa gì → hai worker chọn cùng một job; B chờ A commit rồi UPDATE lại chính job đó
UPDATE r04.jobs
SET status = 'running', attempts = attempts + 1, locked_at = now(), locked_by = 'worker-1'
WHERE id = (SELECT id FROM r04.jobs WHERE status = 'queued' AND run_at <= now() ORDER BY priority DESC, run_at, id LIMIT 1)
RETURNING id;
