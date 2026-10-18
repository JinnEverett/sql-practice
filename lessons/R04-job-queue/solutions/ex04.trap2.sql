-- sai: mọi job treo đều về 'queued', kể cả job 11 đã hết lượt thử → vòng lặp thử vô hạn
UPDATE r04.jobs
SET status = 'queued', locked_at = NULL, locked_by = NULL, last_error = 'reclaimed: worker timeout'
WHERE status = 'running' AND locked_at < now() - interval '5 minutes';
