-- sai: không bỏ dấu ở câu hỏi → 'chỉ mục' vẫn khớp vì cả hai có dấu? Đây là trap về unaccent: bỏ dấu văn bản nhưng không bỏ dấu câu hỏi → 0 dòng
WITH q AS (SELECT plainto_tsquery('simple', 'chỉ mục') AS query),
     d AS (SELECT a.id, a.title, setweight(to_tsvector('simple', unaccent(a.title)), 'A') || setweight(to_tsvector('simple', unaccent(a.body)), 'B') AS vec FROM r11.articles a)
SELECT d.id, d.title, round(ts_rank_cd(d.vec, q.query)::numeric, 4) AS rank FROM d, q WHERE d.vec @@ q.query ORDER BY rank DESC, d.id;
