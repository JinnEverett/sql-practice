-- db: shop_m
-- mode: check
-- Giải thích: `count(*)` chính xác trên 3.2M events phải đọc cả bảng (45 243 page) chỉ để hiện "bao nhiêu kết quả". UI chỉ cần biết "≥ 1000 hay không": đếm trong subquery có LIMIT 1001 và dừng ngay khi đủ:
--   335 buffers, không phụ thuộc kích thước bảng (khi nhóm dòng khớp đủ dày). Nếu cần số chính xác thì cache/bảng tổng hợp (R12); số gần đúng thì reltuples/EXPLAIN.
-- Bẫy: count(*) rồi LEAST/CASE ở ngoài (vẫn đọc hết); LIMIT đặt SAU count (vô nghĩa).
-- query
SELECT count(*) FROM (SELECT 1 FROM events WHERE event_type = 'search' LIMIT 1001) t;
