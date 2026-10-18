-- db: shop_m
-- mode: check
-- Giải thích: ILIKE '%…%' không có tiền tố cố định nên B-tree vô dụng. pg_trgm cắt chuỗi thành các trigram (3 ký tự); GIN ánh xạ trigram → dòng:
--   45 buffers (4 MB index). GiST trigram nhẹ hơn khi ghi nhưng đọc nhiều hơn (417 buffers). Cả hai đều thắng Seq Scan 1 526.
-- Bẫy: text_pattern_ops (chỉ phục vụ LIKE 'abc%'); `gin (email)` không có operator class mặc định cho text → lỗi; quên lower() — không cần: ILIKE đã hỗ trợ bởi trigram.
CREATE INDEX ON users USING gin (email gin_trgm_ops);
