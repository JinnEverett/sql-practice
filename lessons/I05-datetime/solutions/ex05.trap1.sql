SELECT id, status, created_at, justify_hours(date_trunc('hour', timestamptz '2026-10-01 00:00+07' - created_at)) AS waited
FROM orders WHERE status = 'pending' AND created_at < timestamptz '2026-10-01 00:00+07' - interval '3 days' ORDER BY created_at, id;
