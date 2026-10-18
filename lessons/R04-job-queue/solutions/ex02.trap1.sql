-- sai: lấy 3 job có id nhỏ nhất, không theo ưu tiên (1, 2, 3)
UPDATE r04.jobs
SET status = 'running', attempts = attempts + 1, locked_at = now(), locked_by = 'worker-1'
WHERE id IN (SELECT id FROM r04.jobs WHERE status = 'queued' AND run_at <= now() ORDER BY id LIMIT 3 FOR UPDATE SKIP LOCKED)
RETURNING id;
