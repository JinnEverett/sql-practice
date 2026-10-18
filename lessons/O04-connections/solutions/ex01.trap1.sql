-- Lời giải SAI: coi cả 100 chỗ là của ứng dụng, quên phần dành riêng cho superuser.
SELECT setting::int AS usable_connections FROM pg_settings WHERE name = 'max_connections';
