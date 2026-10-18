-- Lời giải SAI: so sánh LSN như chuỗi. '0/9000000' > '0/10000000' đúng với text ('9' > '1') nhưng sai với số.
SELECT s.user_id,
       (SELECT count(*) FROM o06.replicas_now r
         WHERE s.last_write_lsn IS NULL OR r.replay_lsn::text >= s.last_write_lsn::text)::int AS eligible_replicas,
       CASE WHEN EXISTS (SELECT 1 FROM o06.replicas_now r
                          WHERE s.last_write_lsn IS NULL OR r.replay_lsn::text >= s.last_write_lsn::text)
            THEN 'replica' ELSE 'primary' END AS route
FROM o06.sessions s
ORDER BY s.user_id;
