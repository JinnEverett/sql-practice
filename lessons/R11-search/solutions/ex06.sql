-- db: shop_m
-- mode: check
-- Giải thích: muốn lưu sẵn tsvector đã bỏ dấu và đánh index GIN, biểu thức phải IMMUTABLE. Hàm unaccent(text) mặc định chỉ STABLE (kết quả phụ thuộc từ điển),
--   nên cột GENERATED và index biểu thức từ chối nó (lỗi 42P17: generation expression is not immutable). Cách chuẩn: bọc trong hàm IMMUTABLE của riêng bạn,
--   gọi unaccent bản hai tham số với tên từ điển CỐ ĐỊNH ('public.unaccent'): vì từ điển không đổi nên khai báo IMMUTABLE là chấp nhận được (và là cách khuyến nghị).
--   Cột sinh STORED được Postgres tự cập nhật khi name đổi; GIN trên cột này phục vụ toán tử @@. Truy vấn phải dùng CÙNG hàm bọc để bỏ dấu câu hỏi.
-- Bẫy: dùng unaccent() trực tiếp trong GENERATED/INDEX (42P17); quên bỏ dấu câu hỏi bằng cùng hàm; dựng tsvector mỗi lần truy vấn thay vì lưu sẵn + index (Seq Scan).
CREATE FUNCTION public.f_unaccent(text) RETURNS text
LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT
AS $$ SELECT public.unaccent('public.unaccent', $1) $$;

ALTER TABLE products
  ADD COLUMN search_vec tsvector GENERATED ALWAYS AS (to_tsvector('simple', public.f_unaccent(name))) STORED;
CREATE INDEX products_search_vec_idx ON products USING gin (search_vec);
