-- db: lab
-- mode: check
-- reset
-- Giải thích: B mở REPEATABLE READ và giữ snapshot cũ hơn lần UPDATE: mọi phiên bản chết do UPDATE sau thời điểm đó "chưa được dọn" (cannot be removed yet) ở BẤT KỲ bảng nào của DB.
--   pg_stat_activity.backend_xmin cho thấy session nào giữ xmin horizon. Kết thúc nó (pg_terminate_backend, hoặc pg_cancel_backend để hủy câu đang chạy) thì VACUUM dọn được.
--   Lọc đủ hẹp: application_name hoặc backend_xmin IS NOT NULL kèm pid khác mình; không `pg_terminate_backend` cả hệ thống.
-- Bẫy: VACUUM nhiều lần (vô ích); VACUUM FULL (cũng không dọn được tuple mà snapshot còn thấy... và khóa bảng); giết mọi backend.
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE application_name = 'p07_report';
