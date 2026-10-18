-- Lời giải SAI: gom mọi trạng thái idle* vào một ngưỡng 60 s nên cắt cả kết nối idle chưa quá lâu (pid 109) và quên monitor.
SELECT pid, usename, application_name,
       CASE WHEN state LIKE 'idle in transaction%' THEN 'idle_in_tx' ELSE 'idle_long' END AS reason
FROM o04.activity_snapshot
WHERE state LIKE 'idle%' AND idle_s > 60
ORDER BY pid;
