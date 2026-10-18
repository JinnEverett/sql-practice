-- db: lab
-- reset
-- ordered
-- expect-rows: 7
-- Giải thích: xếp hạng liên quan. Gắn TRỌNG SỐ cho từng phần của tài liệu: setweight(…, 'A') cho tiêu đề (quan trọng nhất), 'B' cho nội dung; nối hai tsvector bằng ||.
--   ts_rank_cd tính theo mật độ phủ (cover density) và dùng trọng số mặc định {D:0.1, C:0.2, B:0.4, A:1.0}: từ khớp ở tiêu đề đóng góp nhiều hơn ở nội dung.
--   Bỏ dấu cả hai phía (văn bản và câu hỏi) để 'chỉ mục' khớp 'chi muc'. Sắp xếp rank giảm dần, id làm tie-breaker để thứ tự xác định.
-- Bẫy: ts_rank trên tsvector không có trọng số (mọi chỗ khớp ngang nhau); quên lọc @@ (trả cả bài không khớp với rank 0); sắp xếp theo rank mà thiếu tie-breaker.
WITH q AS (SELECT plainto_tsquery('simple', unaccent('chỉ mục')) AS query),
     d AS (SELECT a.id, a.title,
                  setweight(to_tsvector('simple', unaccent(a.title)), 'A') || setweight(to_tsvector('simple', unaccent(a.body)), 'B') AS vec
           FROM r11.articles a)
SELECT d.id, d.title, round(ts_rank_cd(d.vec, q.query)::numeric, 4) AS rank
FROM d, q
WHERE d.vec @@ q.query
ORDER BY rank DESC, d.id;
