-- db: shop_m
-- mode: check
-- Giải thích: index trên user_id biến Parallel Seq Scan 11 929 buffers thành Index Scan ~34 buffers (3–4 page index + ~28 dòng nằm rải trong heap).
--   28 dòng của 1 khách nằm ở nhiều page heap khác nhau (đơn id tăng theo thời gian, user_id thì không) nên số buffers ≈ số dòng.
-- Bẫy: index trên cột khác (status, created_at); index trên lower(user_id)…
CREATE INDEX ON orders (user_id);
