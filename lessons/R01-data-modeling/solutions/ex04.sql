-- db: lab
-- mode: check
-- reset
-- Giải thích: UNIQUE thường coi mọi NULL là KHÁC nhau, nên (1, NULL) chèn được nhiều lần → nhiều "giá toàn quốc" cho cùng sản phẩm.
--   Postgres 15+: UNIQUE NULLS NOT DISTINCT coi NULL = NULL. Cách cũ/khác: unique index trên biểu thức coalesce(region, '').
-- Bẫy: UNIQUE (product_id, region) trông đúng nhưng không chặn được trùng khi region IS NULL.
ALTER TABLE r01.price_list ADD CONSTRAINT price_list_uq UNIQUE NULLS NOT DISTINCT (product_id, region);
