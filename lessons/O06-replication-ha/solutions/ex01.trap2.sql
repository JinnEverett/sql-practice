-- Lời giải SAI: đảo thứ tự tham số nên mọi số lag đều ra số ÂM.
SELECT replica,
       pg_wal_lsn_diff(flush_lsn, sent_lsn)   AS transfer_lag_bytes,
       pg_wal_lsn_diff(replay_lsn, flush_lsn) AS apply_lag_bytes,
       pg_wal_lsn_diff(replay_lsn, sent_lsn)  AS total_lag_bytes
FROM o06.replica_status
ORDER BY total_lag_bytes DESC, replica;
