-- db: lab
-- mode: check
-- reset
-- Giải thích: `SELECT *` kéo cả cột body 60 KB (nằm ở TOAST) về client dù app chỉ cần id, title. EXPLAIN (ANALYZE) thường KHÔNG thấy chi phí này vì không detoast; EXPLAIN (ANALYZE, SERIALIZE) cho thấy
--   3 225 buffers và 17.8 MB output. Chỉ chọn cột cần: 72 → ít buffers, output 7 kB. Thêm: SELECT * làm Index Only Scan bất khả và vỡ khi ai đó thêm cột.
-- Bẫy: SELECT * hoặc thêm body "cho tiện"; chỉ đo bằng EXPLAIN ANALYZE thường rồi kết luận "nhanh".
-- query
SELECT id, title FROM p09.docs WHERE kind = 'long';
