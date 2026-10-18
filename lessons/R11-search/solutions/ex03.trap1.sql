-- sai: không gắn trọng số → tiêu đề và nội dung ngang nhau
WITH q AS (SELECT plainto_tsquery('simple', unaccent('chỉ mục')) AS query),
     d AS (SELECT a.id, a.title, to_tsvector('simple', unaccent(a.title || ' ' || a.body)) AS vec FROM r11.articles a)
SELECT d.id, d.title, round(ts_rank_cd(d.vec, q.query)::numeric, 4) AS rank FROM d, q WHERE d.vec @@ q.query ORDER BY rank DESC, d.id;
