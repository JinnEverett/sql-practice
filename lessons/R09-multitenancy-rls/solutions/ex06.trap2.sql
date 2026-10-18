-- sai: bảng tạo không có INCLUDING ALL (mất PK, CHECK, identity) và không cấp quyền
CREATE FUNCTION r09.provision_tenant(p_slug text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_slug !~ '^[a-z][a-z0-9_]{0,40}$' THEN RAISE EXCEPTION 'slug không hợp lệ' USING ERRCODE = '22023'; END IF;
  EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', 't_' || p_slug);
  EXECUTE format('CREATE TABLE IF NOT EXISTS %I.invoices (LIKE r09.tpl_invoices)', 't_' || p_slug);
END $$;
