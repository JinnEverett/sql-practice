-- db: lab
-- mode: query
-- ordered
-- reset
-- expect-rows: 5
-- Giải thích: WAL đi qua sent → write → flush → replay. "Chưa tới nơi" = sent − flush (đang trên đường hoặc chưa fsync ở replica);
--   "tới rồi nhưng chưa áp dụng" = flush − replay (replica đang bận replay, ví dụ vì một xung đột); tổng = sent − replay.
--   Hai con số này chỉ cho hướng điều tra khác nhau: transfer lag lớn → mạng/đĩa của replica; apply lag lớn → replay bị chặn hoặc CPU/I/O của replica.
--   pg_wal_lsn_diff(a, b) = a − b tính bằng byte (numeric); LSN là số 64-bit, không so sánh/trừ bằng chuỗi.
-- Bẫy: dùng write_lsn thay flush_lsn (WAL đã write chưa chắc đã fsync); đảo thứ tự tham số (ra số âm); quên ORDER BY phụ theo replica.
SELECT replica,
       pg_wal_lsn_diff(sent_lsn, flush_lsn)   AS transfer_lag_bytes,
       pg_wal_lsn_diff(flush_lsn, replay_lsn) AS apply_lag_bytes,
       pg_wal_lsn_diff(sent_lsn, replay_lsn)  AS total_lag_bytes
FROM o06.replica_status
ORDER BY total_lag_bytes DESC, replica;
