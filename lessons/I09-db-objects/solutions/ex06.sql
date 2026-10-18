-- db: lab
-- mode: check
-- reset
-- Giải thích: trigger = hàm trigger (RETURNS trigger) + CREATE TRIGGER gắn vào bảng. AFTER UPDATE OF price chỉ kích hoạt khi cột price nằm trong SET;
--   WHEN (OLD.price IS DISTINCT FROM NEW.price) lọc ngay ở mức engine, không gọi hàm khi giá không đổi (IS DISTINCT FROM an toàn với NULL).
--   FOR EACH ROW: mỗi dòng đổi giá một bản ghi lịch sử, UPDATE hàng loạt cũng đủ. Trigger AFTER chạy trong cùng transaction với UPDATE:
--   rollback UPDATE thì lịch sử cũng mất, đúng như mong muốn.
-- Bẫy: FOR EACH STATEMENT (không có OLD/NEW theo dòng); quên điều kiện WHEN → ghi lịch sử cả khi giá không đổi ("UPDATE … SET price = price");
--   RETURN NULL/NEW trong AFTER trigger không có ý nghĩa (giá trị trả về bị bỏ qua).
CREATE FUNCTION i09.log_price_change() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO i09.price_history (product_id, old_price, new_price) VALUES (OLD.id, OLD.price, NEW.price);
  RETURN NULL;
END $$;

CREATE TRIGGER trg_products_price_history
AFTER UPDATE OF price ON i09.products
FOR EACH ROW
WHEN (OLD.price IS DISTINCT FROM NEW.price)
EXECUTE FUNCTION i09.log_price_change();
