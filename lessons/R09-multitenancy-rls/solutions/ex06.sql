-- db: lab
-- mode: check
-- reset
-- Giải thích: schema-per-tenant = mỗi tenant một schema `t_<slug>` chứa bảng riêng; cô lập mạnh (khóa quyền theo schema, backup/restore riêng, di chuyển tenant dễ),
--   nhưng số object nhân lên theo số tenant (hàng nghìn tenant × hàng chục bảng làm catalog phình, migration phải chạy N lần). Hàm provision tạo schema từ khuôn:
--   `CREATE TABLE … (LIKE r09.tpl_invoices INCLUDING ALL)` sao chép cột, PK, CHECK, default, identity, index.
--   Tên schema ghép từ đầu vào của người dùng → CHẶN SQL injection bằng (1) kiểm tra định dạng slug và (2) format('%I') để trích dẫn định danh. IF NOT EXISTS để gọi lại không lỗi (idempotent).
-- Bẫy: nối chuỗi 'CREATE SCHEMA ' || p_slug (injection); quên cấp quyền cho role ứng dụng; INCLUDING ALL bị bỏ nên mất PK/CHECK; schema trùng tên với schema hệ thống.
CREATE FUNCTION r09.provision_tenant(p_slug text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE s text := 't_' || p_slug;
BEGIN
  IF p_slug !~ '^[a-z][a-z0-9_]{0,40}$' THEN
    RAISE EXCEPTION 'slug không hợp lệ: %', p_slug USING ERRCODE = '22023';
  END IF;
  EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', s);
  EXECUTE format('CREATE TABLE IF NOT EXISTS %I.invoices (LIKE r09.tpl_invoices INCLUDING ALL)', s);
  EXECUTE format('GRANT USAGE ON SCHEMA %I TO r09_app', s);
  EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON %I.invoices TO r09_app', s);
END $$;
