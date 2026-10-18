-- db: lab
-- mode: check
-- reset
-- Giải thích: hàm SQL một câu lệnh, Postgres có thể "inline" thân hàm vào truy vấn gọi nó. IMMUTABLE = cùng đối số luôn cùng kết quả,
--   không đọc bảng: nhờ đó dùng được trong index expression và planner có thể tính trước khi đối số là hằng. STRICT = đối số NULL → trả NULL
--   mà không chạy thân hàm. round(…, 0) vì VND không có lẻ.
-- Bẫy: quên IMMUTABLE → mặc định VOLATILE: hàm PL/pgSQL kiểu này không tạo được index (42P17), còn hàm SQL đơn giản có thể lọt qua vì được inline
--   lúc tạo index (đã thử) nhưng planner vẫn coi là VOLATILE ở mọi chỗ khác; đánh dấu IMMUTABLE cho hàm đọc bảng/now() là nói dối planner (index sai âm thầm).
CREATE FUNCTION i09.vat_incl(amount numeric, rate numeric DEFAULT 0.08)
RETURNS numeric
LANGUAGE sql IMMUTABLE STRICT
AS $$ SELECT round(amount * (1 + rate), 0) $$;
