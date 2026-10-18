ALTER TABLE p04.log SET (autovacuum_enabled = true, autovacuum_analyze_scale_factor = 0.005, autovacuum_analyze_threshold = 1000);
VACUUM (ANALYZE) p04.log;
