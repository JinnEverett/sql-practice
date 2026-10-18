-- Lời giải SAI: chỉ xét lag theo byte nên bỏ sót r3 (chỉ 1 MB nhưng dữ liệu cũ 9 giây).
SELECT replica,
       CASE WHEN state <> 'streaming' THEN 'NOT_STREAMING'
            WHEN pg_wal_lsn_diff(sent_lsn, replay_lsn) > 16777216 THEN 'LAGGING'
            ELSE 'OK'
       END AS status
FROM o06.replica_status
ORDER BY replica;
