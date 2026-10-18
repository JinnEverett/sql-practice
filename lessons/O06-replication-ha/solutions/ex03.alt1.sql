-- Cách đúng khác: LEFT JOIN + count có điều kiện, route suy ra từ số đếm.
SELECT s.user_id,
       count(r.replica)::int AS eligible_replicas,
       CASE WHEN count(r.replica) > 0 THEN 'replica' ELSE 'primary' END AS route
FROM o06.sessions s
LEFT JOIN o06.replicas_now r ON s.last_write_lsn IS NULL OR r.replay_lsn >= s.last_write_lsn
GROUP BY s.user_id
ORDER BY s.user_id;
