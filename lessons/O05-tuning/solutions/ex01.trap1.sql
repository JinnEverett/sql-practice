-- Lời giải SAI: coi cột setting (đơn vị khác nhau từng tham số) là MB.
SELECT name, round(setting::numeric, 1) AS mb
FROM pg_settings
WHERE name IN ('shared_buffers', 'work_mem', 'maintenance_work_mem', 'effective_cache_size')
ORDER BY name;
