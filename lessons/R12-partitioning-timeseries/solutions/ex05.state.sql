SELECT relname, relispartition AS is_partition FROM pg_class WHERE relnamespace = 'r12'::regnamespace AND relname LIKE 'events_p_2026_%' AND relkind = 'r' ORDER BY relname;
SELECT 'tổng số dòng trong events_p' AS what, count(*)::text AS value FROM r12.events_p;
