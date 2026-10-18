-- Lời giải SAI: không xét state nên r4 (catchup, lag 96 MB) bị gắn LAGGING thay vì NOT_STREAMING.
SELECT replica,
       CASE WHEN pg_wal_lsn_diff(sent_lsn, replay_lsn) > 16777216 OR replay_lag > interval '5 seconds' THEN 'LAGGING'
            ELSE 'OK'
       END AS status
FROM o06.replica_status
ORDER BY replica;
