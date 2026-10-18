SELECT relname, seq_scan, coalesce(idx_scan, 0) AS idx_scan, seq_tup_read, pg_size_pretty(pg_relation_size(relid)) AS size
FROM pg_stat_user_tables WHERE schemaname = 'o03' AND seq_scan > coalesce(idx_scan, 0) ORDER BY seq_tup_read DESC;
