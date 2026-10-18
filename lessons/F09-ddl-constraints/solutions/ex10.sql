-- db: lab
-- mode: check
-- reset
-- Giải thích: ALTER COLUMN … TYPE … USING <biểu thức> chuyển dữ liệu ngay khi đổi kiểu. regexp_replace(price, '[^0-9]', '', 'g')
--   bỏ mọi ký tự không phải chữ số (dấu chấm phân cách nghìn, 'đ', khoảng trắng). Chỉ đúng vì giá VND không có phần lẻ.
--   Lưu ý vận hành: đổi kiểu cột thường GHI LẠI CẢ BẢNG và giữ ACCESS EXCLUSIVE lock suốt thời gian đó (xem bonus, R10).
-- Bẫy: price::numeric thẳng → lỗi với 'đ'; replace('.', '') vẫn còn 'đ' và khoảng trắng; quên CHECK.
ALTER TABLE f09.imports
  ALTER COLUMN price TYPE numeric(12,2) USING regexp_replace(price, '[^0-9]', '', 'g')::numeric;
ALTER TABLE f09.imports ADD CONSTRAINT imports_price_nonneg CHECK (price >= 0);
