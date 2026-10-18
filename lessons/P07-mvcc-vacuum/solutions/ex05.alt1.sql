SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE backend_xmin IS NOT NULL AND pid <> pg_backend_pid() AND datname = current_database();
