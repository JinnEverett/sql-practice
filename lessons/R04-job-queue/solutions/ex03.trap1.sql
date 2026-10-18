-- sai: không phân biệt hết lượt thử → job 9 lại về 'queued' và sẽ bị thử lần thứ 4
UPDATE r04.jobs
SET status = 'queued', run_at = now() + interval '10 seconds' * power(2, attempts), locked_at = NULL, locked_by = NULL, last_error = 'timeout'
WHERE id IN (5, 9) AND status = 'running';
