SELECT attname, round(abs(correlation)::numeric, 1) AS abs_corr, 'Index Scan' AS node
FROM pg_stats WHERE schemaname = 'p03' AND tablename = 'o' AND attname IN ('user_id', 'created_at') ORDER BY attname;
