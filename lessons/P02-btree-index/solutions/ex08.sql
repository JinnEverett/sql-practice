-- db: lab
-- mode: check
-- reset
-- Giải thích: ord_user trùng hệt ord_user_dup; ord_user và ord_user_created là tiền tố của ord_user_created_stat → thừa.
--   Giữ (user_id, created_at, status) phục vụ 3 query đầu; ord_status cần cho query 4 (status hiếm: 297 dòng, 300 buffers thay vì 2 500).
--   Bỏ 3 index = ghi nhanh hơn và bảng + index nhẹ đi khoảng 1 000 page.
-- Bẫy: chỉ bỏ index trùng hệt; bỏ cả ord_status (query 4 quay về Seq Scan).
DROP INDEX p02.ord_user, p02.ord_user_dup, p02.ord_user_created;
