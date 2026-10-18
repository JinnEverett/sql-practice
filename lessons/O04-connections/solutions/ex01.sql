-- db: lab
-- mode: query
-- expect-rows: 1
-- Giải thích: số kết nối một role thường dùng được = max_connections trừ MỌI phần dành riêng.
--   superuser_reserved_connections: chỉ superuser dùng được. reserved_connections (từ PG16): chỉ role thuộc pg_use_reserved_connections.
--   Hết chỗ thì app thường nhận "remaining connection slots are reserved…" (khi chạm phần dành riêng) hoặc "sorry, too many clients already".
-- Bẫy: chỉ đọc max_connections rồi tưởng có đủ 100 chỗ; quên reserved_connections (PG16+) vì tài liệu cũ không có.
SELECT (SELECT setting::int FROM pg_settings WHERE name = 'max_connections')
     - (SELECT setting::int FROM pg_settings WHERE name = 'superuser_reserved_connections')
     - (SELECT setting::int FROM pg_settings WHERE name = 'reserved_connections') AS usable_connections;
