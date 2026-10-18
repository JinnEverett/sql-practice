-- O01 · Security. Chạy trên DB `lab`, schema `o01`. Chạy lại bao nhiêu lần cũng được (reset về ban đầu).
-- Role là đối tượng của CẢ cluster, không thuộc schema: script xóa các role của bài (nếu có) trước khi dựng lại.
DO $$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['o01_ro', 'o01_app', 'o01_support', 'o01_tenant_app'] LOOP
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('DROP OWNED BY %I', r);
      EXECUTE format('DROP ROLE %I', r);
    END IF;
  END LOOP;
END $$;
DROP SCHEMA IF EXISTS o01 CASCADE;
CREATE SCHEMA o01;

CREATE TABLE o01.customers (
  id            int PRIMARY KEY,
  tenant_id     int NOT NULL,
  name          text NOT NULL,
  email         text NOT NULL UNIQUE,
  password_hash text NOT NULL
);
INSERT INTO o01.customers VALUES
  (1, 1, 'An',   'an@x.vn',   'hash-an'),
  (2, 1, 'Bình', 'binh@x.vn', 'hash-binh'),
  (3, 1, 'Chi',  'chi@x.vn',  'hash-chi'),
  (4, 2, 'Dũng', 'dung@x.vn', 'hash-dung'),
  (5, 2, 'Em',   'em@x.vn',   'hash-em'),
  (6, 2, 'Phúc', 'phuc@x.vn', 'hash-phuc');

CREATE TABLE o01.orders (
  id          int PRIMARY KEY,
  tenant_id   int NOT NULL,
  customer_id int NOT NULL REFERENCES o01.customers(id),
  status      text NOT NULL,
  total       numeric(12,2) NOT NULL
);
-- 10 đơn: đơn 1–6 của tenant 1 (khách 1–3), đơn 7–10 của tenant 2 (khách 4–6)
INSERT INTO o01.orders VALUES
  (1, 1, 1, 'paid',      100000), (2, 1, 1, 'delivered', 200000), (3, 1, 2, 'paid',      300000),
  (4, 1, 2, 'cancelled', 400000), (5, 1, 3, 'delivered', 500000), (6, 1, 3, 'paid',      600000),
  (7, 2, 4, 'paid',      700000), (8, 2, 4, 'delivered', 800000), (9, 2, 5, 'paid',      900000),
  (10, 2, 6, 'cancelled', 1000000);

-- ex05: hàm TÌM KHÁCH đang bị chèn SQL (ghép chuỗi). Đừng dùng nó làm mẫu!
CREATE FUNCTION o01.find_customer_bad(p_email text) RETURNS TABLE (id int, name text)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY EXECUTE 'SELECT id, name FROM o01.customers WHERE email = ''' || p_email || '''';
END $$;

-- ex06: role của ứng dụng multi-tenant (đã có quyền bảng, CHƯA có row level security)
CREATE ROLE o01_tenant_app NOLOGIN;
GRANT USAGE ON SCHEMA o01 TO o01_tenant_app;
GRANT SELECT, INSERT ON o01.orders TO o01_tenant_app;
