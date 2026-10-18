-- sai: ghi cả hàng và ghi cả khi không có thay đổi
CREATE FUNCTION r05.audit_product_changes() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO r05.product_audit2 (op, row_id, changes) VALUES (TG_OP, coalesce(NEW.id, OLD.id), to_jsonb(coalesce(NEW, OLD)));
  RETURN NULL;
END $$;
CREATE TRIGGER products_audit AFTER INSERT OR UPDATE OR DELETE ON r05.products FOR EACH ROW EXECUTE FUNCTION r05.audit_product_changes();
