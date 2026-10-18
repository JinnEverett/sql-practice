-- Lời giải SAI: so state bằng '=' nên bỏ sót "idle in transaction (aborted)" (pid 105).
SELECT pid, usename, application_name, reason
FROM (
  SELECT pid, usename, application_name,
         CASE WHEN state = 'idle in transaction' AND idle_s > 60 THEN 'idle_in_tx'
              WHEN state = 'idle' AND idle_s > 900 THEN 'idle_long'
         END AS reason
  FROM o04.activity_snapshot
  WHERE usename <> 'monitor'
) s
WHERE reason IS NOT NULL
ORDER BY pid;
