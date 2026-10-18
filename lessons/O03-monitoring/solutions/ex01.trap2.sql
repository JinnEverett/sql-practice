SELECT left(query, 80) AS query, calls, round(total_exec_time::numeric, 1) AS total_ms, round(mean_exec_time::numeric, 2) AS mean_ms
FROM pg_stat_statements ORDER BY calls DESC LIMIT 5;
