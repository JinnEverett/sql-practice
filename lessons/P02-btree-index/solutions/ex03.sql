-- db: shop_m
-- mode: check
-- Giải thích: cột equality chung (user_id) đứng đầu → cả ba query dùng được tiền tố. (user_id, created_at): (a) tiền tố 1 cột,
--   (b) lọc status trên heap sau khi index chọn ra 28 dòng, (c) index cond 2 cột → 7 buffers. Đảo thành (created_at, user_id): (c) tốn 524 buffers
--   và (a) quay về Seq Scan (cột đầu có ~1M giá trị nên skip scan của Postgres 18 không giúp).
-- Bẫy: (created_at, user_id); tạo hai ba index riêng lẻ (mỗi cái một query).
CREATE INDEX ON orders (user_id, created_at);
