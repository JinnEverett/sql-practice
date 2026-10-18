-- db: lab
-- mode: query
-- ordered
-- expect-rows: 4
-- Giải thích: pg_settings.setting là chuỗi KHÔNG cùng đơn vị (shared_buffers tính bằng khối 8kB, work_mem bằng kB, ...), cột `unit` mới cho biết đơn vị.
--   current_setting() trả chuỗi có đơn vị ("256MB", "4096MB") và pg_size_bytes() đổi chuỗi đó sang byte, nên tránh được bài toán đơn vị.
-- Bẫy: đọc setting::bigint rồi coi là MB (shared_buffers sẽ ra 32768); quên effective_cache_size (không cấp phát gì, nhưng là tham số bộ nhớ của planner).
SELECT name,
       round(pg_size_bytes(current_setting(name)) / 1048576.0, 1) AS mb
FROM pg_settings
WHERE name IN ('shared_buffers', 'work_mem', 'maintenance_work_mem', 'effective_cache_size')
ORDER BY name;
