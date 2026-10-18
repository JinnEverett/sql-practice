-- db: lab
SELECT count(*) AS n_reviews, count(rating) AS n_rated,
       round(avg(rating), 2) AS avg_rated, round(avg(coalesce(rating, 0)), 2) AS avg_as_zero
FROM f03.reviews WHERE product_id = 2;
