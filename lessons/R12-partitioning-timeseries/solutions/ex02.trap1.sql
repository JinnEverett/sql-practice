-- sai: bọc cột trong hàm → đúng kết quả nhưng quét cả 6 partition
SELECT count(*) AS n_events, round(avg(value), 2) AS avg_value FROM r12.events_p
WHERE date_trunc('month', ts AT TIME ZONE 'Asia/Ho_Chi_Minh') = timestamp '2026-03-01';
