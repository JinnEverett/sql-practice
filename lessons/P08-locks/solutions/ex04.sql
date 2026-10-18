-- db: lab
-- mode: check
-- reset
-- Giải thích: một báo cáo đọc lâu giữ ACCESS SHARE trên bảng. ALTER TABLE cần ACCESS EXCLUSIVE nên phải CHỜ báo cáo; nhưng trong lúc chờ nó đứng đầu hàng đợi lock và MỌI truy vấn mới (kể cả SELECT)
--   xếp sau nó → cả site đứng dù ALTER chưa chạy gì. lock_timeout làm ALTER bỏ cuộc sau 1 giây (ERROR 55P03) và nhả hàng đợi; deploy thử lại sau (vòng lặp retry ở công cụ migration).
-- Bẫy: ALTER TABLE trơn trên bảng đang có truy vấn dài; lock_timeout quá lớn (20 giây vẫn đứng 20 giây).
SET lock_timeout = '1s';
ALTER TABLE p08.big ADD COLUMN x int;
