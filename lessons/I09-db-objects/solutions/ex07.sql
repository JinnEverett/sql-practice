-- db: lab
-- mode: check
-- reset
-- Giải thích: trigger BEFORE ROW chạy trước khi dòng được ghi, nên vừa kiểm tra vừa trừ kho trong cùng câu lệnh; ném lỗi thì cả INSERT bị hủy
--   (cả nhiều dòng của một INSERT … SELECT, vì cùng một statement/transaction). Mỗi UPDATE products lấy khóa dòng nên hai đơn đặt cùng lúc
--   hàng cuối cùng sẽ xếp hàng chứ không cùng thành công (khác với "SELECT stock rồi UPDATE" ở ứng dụng).
--   Kiểm tra bằng UPDATE … WHERE stock >= quantity rồi xem FOUND gọn hơn SELECT trước. Cần trigger cho cả DELETE (và UPDATE quantity) nếu muốn
--   kho luôn đúng; ở đây yêu cầu INSERT và DELETE.
-- Bẫy: AFTER trigger mà không kiểm tra → stock âm; SELECT stock rồi mới UPDATE (race giữa hai session); quên trả kho khi xóa dòng;
--   ném lỗi sai mã (đề yêu cầu check_violation 23514).
CREATE FUNCTION i09.order_lines_stock() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE i09.products SET stock = stock - NEW.quantity WHERE id = NEW.product_id AND stock >= NEW.quantity;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'không đủ tồn kho cho sản phẩm % (cần %)', NEW.product_id, NEW.quantity USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
  ELSE  -- DELETE
    UPDATE i09.products SET stock = stock + OLD.quantity WHERE id = OLD.product_id;
    RETURN OLD;
  END IF;
END $$;

CREATE TRIGGER trg_order_lines_stock
BEFORE INSERT OR DELETE ON i09.order_lines
FOR EACH ROW EXECUTE FUNCTION i09.order_lines_stock();
