-- db: lab
-- reset
-- ordered
-- expect-rows: 3
-- Giải thích: octet_length = độ dài gốc; pg_column_size = số byte đang lưu. short 96→97 (thêm 1 B header varlena); medium 6 270→117
--   (nén pglz, vẫn inline trong heap); long 60 800→60 800: md5 hex ngẫu nhiên không nén đủ 25% nên pglz bỏ cuộc, giá trị ra bảng TOAST nguyên dạng.
-- Bẫy: dùng octet_length cho cả hai cột (không thấy nén); tưởng giá trị > 2 KB luôn được nén.
SELECT kind,
       round(avg(octet_length(body)))::int       AS avg_len,
       round(avg(pg_column_size(body)))::int     AS avg_stored,
       count(pg_column_compression(body))        AS n_compressed
FROM p01.docs GROUP BY kind ORDER BY avg_len;
