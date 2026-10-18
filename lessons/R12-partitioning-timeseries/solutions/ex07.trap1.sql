-- sai: DO NOTHING giữ nguyên dòng cũ sai của (sensor 1, 2026-03-02)
INSERT INTO r12.metrics_daily (sensor, day, n, sum_value, min_value, max_value)
SELECT sensor, (ts AT TIME ZONE 'Asia/Ho_Chi_Minh')::date, count(*), sum(value), min(value), max(value)
FROM r12.metrics_raw WHERE ts >= '2026-03-01 00:00+07' AND ts < '2026-03-04 00:00+07' GROUP BY 1, 2
ON CONFLICT (sensor, day) DO NOTHING;
