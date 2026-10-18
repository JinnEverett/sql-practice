-- sai: nối chuỗi trực tiếp (SQL injection) và không kiểm tra slug
CREATE FUNCTION r09.provision_tenant(p_slug text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE 'CREATE SCHEMA IF NOT EXISTS t_' || p_slug;
  EXECUTE 'CREATE TABLE IF NOT EXISTS t_' || p_slug || '.invoices (LIKE r09.tpl_invoices INCLUDING ALL)';
  EXECUTE 'GRANT USAGE ON SCHEMA t_' || p_slug || ' TO r09_app';
  EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON t_' || p_slug || '.invoices TO r09_app';
END $$;
