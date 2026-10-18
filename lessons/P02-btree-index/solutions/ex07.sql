-- db: shop_m
-- mode: check
-- Giải thích: DB dùng collation en_US.utf8: thứ tự sắp xếp không phải thứ tự byte nên B-tree thường không biến `LIKE 'abc%'` thành range.
--   text_pattern_ops sắp theo byte → planner đổi LIKE thành `email >= 'hung.pham88' AND email < 'hung.pham89'`: 5 buffers thay vì 1 526.
-- Bẫy: index (email) thường (Seq Scan); index trên lower(email) khi query không bọc lower.
CREATE INDEX ON users (email text_pattern_ops);
