SELECT id, status, attempts,
       CASE WHEN status = 'queued' THEN extract(epoch FROM run_at - now())::int END AS retry_in_s,
       locked_by, last_error
FROM r04.jobs WHERE id IN (5, 9) ORDER BY id;
