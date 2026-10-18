-- db: lab
-- mode: check
-- reset
-- Giải thích: audit bằng trigger ROW-level AFTER INSERT OR UPDATE OR DELETE. Trong hàm trigger: TG_OP là thao tác, OLD/NEW là dòng trước/sau
--   (OLD không có khi INSERT, NEW không có khi DELETE). to_jsonb(OLD)/to_jsonb(NEW) lưu cả dòng không cần liệt kê cột, nên thêm cột vào bảng không phải sửa trigger.
--   AFTER vì ta chỉ ghi nhận thay đổi đã chắc chắn xảy ra (các BEFORE trigger khác có thể đã sửa NEW); trigger AFTER trả NULL được.
--   changed_by dùng current_user (mặc định của cột). Ghi nhận người dùng ứng dụng thật cần truyền qua biến phiên (set_config('app.user', …)).
-- Bẫy: FOR EACH STATEMENT chỉ chạy 1 lần cho UPDATE nhiều dòng (không thấy từng dòng, ngoại trừ transition table); dùng NEW.id khi DELETE gây lỗi/NULL.
CREATE FUNCTION r05.audit_product() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO r05.product_audit (op, row_id, new_row) VALUES (TG_OP, NEW.id, to_jsonb(NEW));
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO r05.product_audit (op, row_id, old_row, new_row) VALUES (TG_OP, NEW.id, to_jsonb(OLD), to_jsonb(NEW));
  ELSE
    INSERT INTO r05.product_audit (op, row_id, old_row) VALUES (TG_OP, OLD.id, to_jsonb(OLD));
  END IF;
  RETURN NULL;
END $$;
CREATE TRIGGER products_audit AFTER INSERT OR UPDATE OR DELETE ON r05.products
  FOR EACH ROW EXECUTE FUNCTION r05.audit_product();
