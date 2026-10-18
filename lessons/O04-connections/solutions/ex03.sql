-- db: lab
-- mode: query
-- ordered
-- reset
-- expect-rows: 5
-- Giải thích: hai loại kết nối "chết" cần cắt, mỗi loại một ngưỡng riêng. `idle in transaction` giữ khóa và chặn VACUUM nên ngưỡng ngắn (60 s);
--   `idle` thuần chỉ chiếm chỗ nên ngưỡng dài (900 s). Trạng thái "idle in transaction (aborted)" có hậu tố nên phải dùng LIKE 'idle in transaction%'.
--   Luôn loại tài khoản giám sát (ở đây `monitor`). Kết quả: 101, 103, 105, 106, 110.
-- Bẫy: state = 'idle in transaction' bỏ sót bản aborted (pid 105); LIKE 'idle%' cho cả hai nhóm cắt nhầm kết nối idle mới (pid 102);
--   quên loại monitor (pid 107); dùng xact_age_s (NULL ở kết nối idle) làm điều kiện.
SELECT pid, usename, application_name, reason
FROM (
  SELECT pid, usename, application_name,
         CASE WHEN state LIKE 'idle in transaction%' AND idle_s > 60 THEN 'idle_in_tx'
              WHEN state = 'idle' AND idle_s > 900 THEN 'idle_long'
         END AS reason
  FROM o04.activity_snapshot
  WHERE usename <> 'monitor'
) s
WHERE reason IS NOT NULL
ORDER BY pid;
