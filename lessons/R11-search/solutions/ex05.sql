-- db: shop_m
-- mode: check
-- Giải thích: ILIKE '%mẫu%' (dấu % ở đầu) không dùng được B-tree. Index GIN với gin_trgm_ops (pg_trgm) lập chỉ mục các trigram của cột, nên LIKE/ILIKE/~ với mẫu bất kỳ
--   (kể cả '%giữa%') tìm được trigram trong index, rồi chỉ kiểm tra lại (Recheck) các dòng ứng viên. Với 100 000 user và mẫu dài ≥ 3 ký tự, plan chuyển từ Seq Scan (1 526 buffer)
--   sang Bitmap Index Scan (khoảng 140 buffer).
-- Bẫy: B-tree (…text_pattern_ops) chỉ giúp mẫu ĐẦU chuỗi 'abc%'; mẫu quá ngắn (< 3 ký tự) không có trigram nên index vô dụng; quên bật extension pg_trgm (đã có sẵn trong shop_*).
CREATE INDEX users_fullname_trgm ON users USING gin (full_name gin_trgm_ops);
-- query
SELECT id, full_name
FROM users
WHERE full_name ILIKE '%nguyễn văn hải%'
ORDER BY id;
