-- db: lab
-- mode: check
-- reset
-- Giải thích: city = 7 (1/50) AND zip = 71 (1/100) nhân độc lập = 100 000 / 5000 = 20 dòng (ước lượng 21), nhưng zip xác định city nên kết quả đúng bằng số dòng
--   của zip = 71: 1 000. Extended statistics kiểu dependencies lưu "zip → city" với độ tin cậy 1.0, planner ước lượng ≈ 1 000.
--   CREATE STATISTICS chỉ tạo định nghĩa; số liệu chỉ có sau ANALYZE.
-- Bẫy: quên ANALYZE; dùng ndistinct (giúp GROUP BY, không giúp WHERE); tạo statistics cho từng cột riêng lẻ.
CREATE STATISTICS addr_dep (dependencies) ON city, zip FROM p04.addr;
ANALYZE p04.addr;
