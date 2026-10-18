-- Lần 1: thiếu làm tròn 2 chữ số (3.0625…, 2.45…)
select count(*) as n_reviews, count(rating) as n_rated, round(avg(rating),2) as avg_rated, round(avg(coalesce(rating,0)),2) as avg_as_zero from f03.reviews where product_id = 2;
-- Câu hỏi phụ: avg_rated, vì người không chấm sao không nên kéo điểm xuống ✅
