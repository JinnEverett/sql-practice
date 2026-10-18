-- Lời giải SAI: tính chặng truyền bằng write_lsn thay vì flush_lsn (WAL mới write vào OS, chưa chắc đã fsync).
SELECT replica,
       pg_wal_lsn_diff(sent_lsn, write_lsn)   AS transfer_lag_bytes,
       pg_wal_lsn_diff(write_lsn, replay_lsn) AS apply_lag_bytes,
       pg_wal_lsn_diff(sent_lsn, replay_lsn)  AS total_lag_bytes
FROM o06.replica_status
ORDER BY total_lag_bytes DESC, replica;
