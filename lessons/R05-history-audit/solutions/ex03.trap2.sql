-- sai: lọc no-op đúng nhưng lưu cả dòng mới thay vì phần thay đổi old/new
CREATE FUNCTION r05.audit_product_changes() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO r05.product_audit2 (op, row_id, changes) VALUES (TG_OP, coalesce(NEW.id, OLD.id), to_jsonb(coalesce(NEW, OLD)));
  RETURN NULL;
END $$;
CREATE TRIGGER products_audit_ins_del AFTER INSERT OR DELETE ON r05.products FOR EACH ROW EXECUTE FUNCTION r05.audit_product_changes();
CREATE TRIGGER products_audit_upd AFTER UPDATE ON r05.products FOR EACH ROW WHEN (OLD.* IS DISTINCT FROM NEW.*) EXECUTE FUNCTION r05.audit_product_changes();
