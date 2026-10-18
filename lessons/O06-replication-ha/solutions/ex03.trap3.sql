-- Lời giải SAI: INNER JOIN làm mất user 4 (last_write_lsn NULL không khớp điều kiện >=) và user 6 (không có replica nào đủ mới).
SELECT s.user_id, count(*)::int AS eligible_replicas, 'replica' AS route
FROM o06.sessions s
JOIN o06.replicas_now r ON r.replay_lsn >= s.last_write_lsn
GROUP BY s.user_id
ORDER BY s.user_id;
