-- sai: khoảng theo UTC (lệch 7 giờ so với tháng 3 giờ Việt Nam) → sai kết quả dù chỉ quét 1 partition
SELECT count(*) AS n_events, round(avg(value), 2) AS avg_value FROM r12.events_p
WHERE ts >= '2026-03-01 00:00+00' AND ts < '2026-04-01 00:00+00';
