-- sai: trigger mức câu lệnh → chỉ 1 dòng audit cho UPDATE nhiều dòng, và NEW/OLD không dùng được
CREATE FUNCTION r05.audit_product() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO r05.product_audit (op, row_id) VALUES (TG_OP, 0);
  RETURN NULL;
END $$;
CREATE TRIGGER products_audit AFTER INSERT OR UPDATE OR DELETE ON r05.products FOR EACH STATEMENT EXECUTE FUNCTION r05.audit_product();
