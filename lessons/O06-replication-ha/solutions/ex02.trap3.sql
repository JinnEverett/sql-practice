-- Lời giải SAI: coi replay_lag NULL là "không rõ nên báo động", nên r1 (nhàn rỗi, đã bắt kịp, lag 0 byte) bị gắn LAGGING.
SELECT replica,
       CASE WHEN state <> 'streaming' THEN 'NOT_STREAMING'
            WHEN pg_wal_lsn_diff(sent_lsn, replay_lsn) > 16777216 OR coalesce(replay_lag, interval '1 hour') > interval '5 seconds' THEN 'LAGGING'
            ELSE 'OK'
       END AS status
FROM o06.replica_status
ORDER BY replica;
