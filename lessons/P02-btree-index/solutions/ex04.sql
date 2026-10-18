-- db: shop_m
-- mode: check
-- Giải thích: query chỉ cần user_id (lọc, gom nhóm) và total_amount (sum). Đặt total_amount vào INCLUDE thì leaf index có đủ dữ liệu →
--   Index Only Scan, Heap Fetches 0 vì bảng all-visible: 222 buffers thay vì 11 445. Index (user_id) trần vẫn phải đọc 55 831 dòng ở heap.
--   Index sắp theo user_id nên GROUP BY không cần Sort (GroupAggregate).
-- Bẫy: index (user_id) trần; INCLUDE sai cột; quên rằng Index Only Scan cần visibility map.
CREATE INDEX ON orders (user_id) INCLUDE (total_amount);
