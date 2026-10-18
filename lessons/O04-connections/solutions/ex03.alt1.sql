-- Cách giải đúng khác: UNION ALL hai nhóm thay vì CASE.
SELECT pid, usename, application_name, 'idle_in_tx' AS reason
FROM o04.activity_snapshot
WHERE usename <> 'monitor' AND state LIKE 'idle in transaction%' AND idle_s > 60
UNION ALL
SELECT pid, usename, application_name, 'idle_long'
FROM o04.activity_snapshot
WHERE usename <> 'monitor' AND state = 'idle' AND idle_s > 900
ORDER BY pid;
