-- db: lab
-- mode: query
-- ordered
-- reset
-- expect-rows: 6
-- Giải thích: mỗi người dùng mang "token" = LSN lần ghi gần nhất. Replica chỉ đọc được dữ liệu của họ khi đã replay tới ít nhất LSN đó (>=, kể cả bằng nhau:
--   replay_lsn là vị trí đã áp dụng xong, nên bằng nghĩa là đã thấy). Không có replica nào đủ mới (user 6) thì đọc primary.
--   Người chưa ghi gì (user 4, last_write_lsn NULL) không có ràng buộc: mọi replica đều đủ mới.
--   So sánh bằng kiểu pg_lsn, KHÔNG bằng chuỗi: '0/9000000' > '0/10000000' đúng với text nhưng 0x9000000 < 0x10000000.
-- Bẫy: ép sang text rồi so sánh; dùng > thay vì >= (user 2 có đúng một replica bằng LSN); INNER JOIN làm mất user 4 (NULL) và user 6 (không có replica nào).
SELECT s.user_id,
       (SELECT count(*) FROM o06.replicas_now r
         WHERE s.last_write_lsn IS NULL OR r.replay_lsn >= s.last_write_lsn)::int AS eligible_replicas,
       CASE WHEN EXISTS (SELECT 1 FROM o06.replicas_now r
                          WHERE s.last_write_lsn IS NULL OR r.replay_lsn >= s.last_write_lsn)
            THEN 'replica' ELSE 'primary' END AS route
FROM o06.sessions s
ORDER BY s.user_id;
