-- db: lab
-- mode: query
-- ordered
-- reset
-- expect-rows: 5
-- Giải thích: kiểm theo thứ tự ưu tiên. Replica không ở trạng thái `streaming` (catchup, startup, backup…) thì chưa phục vụ đúng nghĩa, báo riêng.
--   Replica đang streaming mới xét lag: theo BYTE (khối lượng WAL chưa replay) HOẶC theo THỜI GIAN (độ cũ của dữ liệu).
--   replay_lag là NULL khi replica nhàn rỗi và đã bắt kịp, mà `NULL > interval` là NULL (không phải true) nên CASE rơi xuống `OK`: đúng ý.
--   r3 chỉ lệch 1 MB nhưng cũ 9 s: nếu chỉ nhìn byte sẽ bỏ sót.
-- Bẫy: chỉ xét byte (bỏ sót r3); không xét state (r4 bị gắn LAGGING thay vì NOT_STREAMING); coalesce(replay_lag, '1 hour') coi replica nhàn rỗi là LAGGING (r1).
SELECT replica,
       CASE WHEN state <> 'streaming' THEN 'NOT_STREAMING'
            WHEN pg_wal_lsn_diff(sent_lsn, replay_lsn) > 16777216 OR replay_lag > interval '5 seconds' THEN 'LAGGING'
            ELSE 'OK'
       END AS status
FROM o06.replica_status
ORDER BY replica;
