-- sai: không ghi old_row khi UPDATE/DELETE (mất dữ liệu cũ)
CREATE FUNCTION r05.audit_product() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    INSERT INTO r05.product_audit (op, row_id) VALUES (TG_OP, OLD.id);
  ELSE
    INSERT INTO r05.product_audit (op, row_id, new_row) VALUES (TG_OP, NEW.id, to_jsonb(NEW));
  END IF;
  RETURN NULL;
END $$;
CREATE TRIGGER products_audit AFTER INSERT OR UPDATE OR DELETE ON r05.products FOR EACH ROW EXECUTE FUNCTION r05.audit_product();
