-- sai: nhóm theo ngày UTC (lệch 7 giờ)
INSERT INTO r12.metrics_daily (sensor, day, n, sum_value, min_value, max_value)
SELECT sensor, ts::date, count(*), sum(value), min(value), max(value)
FROM r12.metrics_raw WHERE ts >= '2026-03-01 00:00+07' AND ts < '2026-03-04 00:00+07' GROUP BY 1, 2
ON CONFLICT (sensor, day) DO UPDATE SET n = EXCLUDED.n, sum_value = EXCLUDED.sum_value, min_value = EXCLUDED.min_value, max_value = EXCLUDED.max_value;
