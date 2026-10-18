-- Lời giải SAI: dùng > thay vì >=. Replica có replay_lsn đúng bằng LSN lần ghi đã thấy dữ liệu đó (user 2 có đúng một replica như vậy).
SELECT s.user_id,
       (SELECT count(*) FROM o06.replicas_now r
         WHERE s.last_write_lsn IS NULL OR r.replay_lsn > s.last_write_lsn)::int AS eligible_replicas,
       CASE WHEN EXISTS (SELECT 1 FROM o06.replicas_now r
                          WHERE s.last_write_lsn IS NULL OR r.replay_lsn > s.last_write_lsn)
            THEN 'replica' ELSE 'primary' END AS route
FROM o06.sessions s
ORDER BY s.user_id;
