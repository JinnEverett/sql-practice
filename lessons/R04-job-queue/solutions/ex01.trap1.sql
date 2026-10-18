-- sai: bỏ qua priority → nhận job có run_at sớm nhất (job 8) thay vì job ưu tiên cao nhất (job 3)
UPDATE r04.jobs
SET status = 'running', attempts = attempts + 1, locked_at = now(), locked_by = 'worker-1'
WHERE id = (SELECT id FROM r04.jobs WHERE status = 'queued' AND run_at <= now() ORDER BY run_at, id LIMIT 1 FOR UPDATE SKIP LOCKED)
RETURNING id;
