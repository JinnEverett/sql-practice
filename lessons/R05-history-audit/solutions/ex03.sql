-- db: lab
-- mode: check
-- reset
-- Giải thích: hai cải tiến cho audit: (1) `WHEN (OLD.* IS DISTINCT FROM NEW.*)` ở UPDATE trigger → UPDATE không đổi gì (ORM hay ghi lại cả dòng) không sinh dòng audit nào;
--   (2) chỉ lưu phần THAY ĐỔI: ghép jsonb của OLD và NEW theo key, giữ key có giá trị khác nhau → {"price": {"old": …, "new": …}}.
--   INSERT/DELETE lưu cả dòng (không có "trước/sau" để so). Dùng `IS DISTINCT FROM` (an toàn với NULL) chứ không `<>`.
-- Bẫy: `OLD <> NEW` trên record không so được NULL đúng; so từng cột bằng tay phải sửa mỗi khi thêm cột; quên rằng cột updated_at do ứng dụng tự đổi sẽ khiến mọi UPDATE đều "có thay đổi".
CREATE FUNCTION r05.audit_product_changes() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE d jsonb;
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO r05.product_audit2 (op, row_id, changes) VALUES (TG_OP, NEW.id, to_jsonb(NEW));
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO r05.product_audit2 (op, row_id, changes) VALUES (TG_OP, OLD.id, to_jsonb(OLD));
  ELSE
    SELECT jsonb_object_agg(o.key, jsonb_build_object('old', o.value, 'new', n.value)) INTO d
    FROM jsonb_each(to_jsonb(OLD)) o JOIN jsonb_each(to_jsonb(NEW)) n USING (key)
    WHERE o.value IS DISTINCT FROM n.value;
    INSERT INTO r05.product_audit2 (op, row_id, changes) VALUES (TG_OP, NEW.id, d);
  END IF;
  RETURN NULL;
END $$;
CREATE TRIGGER products_audit_ins_del AFTER INSERT OR DELETE ON r05.products
  FOR EACH ROW EXECUTE FUNCTION r05.audit_product_changes();
CREATE TRIGGER products_audit_upd AFTER UPDATE ON r05.products
  FOR EACH ROW WHEN (OLD.* IS DISTINCT FROM NEW.*) EXECUTE FUNCTION r05.audit_product_changes();
