-- R09 · multi-tenancy: shared table + tenant_id, RLS, schema-per-tenant. Chạy trên DB `lab`. Chạy lại được nhiều lần.
-- Hai role không đăng nhập được, chỉ để SET ROLE giả lập "ứng dụng" và "nhân viên hỗ trợ". Role ở mức cluster nên tồn tại sau khi DROP SCHEMA.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'r09_app') THEN CREATE ROLE r09_app NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'r09_support') THEN CREATE ROLE r09_support NOLOGIN; END IF;
END $$;
DROP SCHEMA IF EXISTS r09 CASCADE;
CREATE SCHEMA r09;
GRANT USAGE ON SCHEMA r09 TO r09_app, r09_support;

CREATE TABLE r09.tenants (id int PRIMARY KEY, name text NOT NULL);
INSERT INTO r09.tenants VALUES (1, 'Acme'), (2, 'Bình Minh'), (3, 'Cẩm Tú');

-- (1) customers / invoices: FK đơn giản, chưa có RLS (ex01, ex02)
CREATE TABLE r09.customers (id int PRIMARY KEY, tenant_id int NOT NULL REFERENCES r09.tenants, name text NOT NULL);
INSERT INTO r09.customers VALUES (1, 1, 'KH A1'), (2, 1, 'KH A2'), (3, 2, 'KH B1'), (4, 2, 'KH B2'), (5, 3, 'KH C1');
CREATE TABLE r09.invoices (
  id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tenant_id   int NOT NULL REFERENCES r09.tenants,
  customer_id int NOT NULL REFERENCES r09.customers,
  amount      numeric(12,2) NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now());
INSERT INTO r09.invoices (tenant_id, customer_id, amount) VALUES
  (1, 1, 100), (1, 1, 200), (1, 2, 300),
  (2, 3, 400), (2, 4, 500),
  (3, 5, 600), (3, 5, 700);
GRANT SELECT, INSERT, UPDATE, DELETE ON r09.invoices, r09.customers TO r09_app;
GRANT SELECT ON r09.invoices, r09.customers TO r09_support;

-- (2) notes: đã bật RLS với policy "ngây thơ" dễ vỡ khi biến phiên chưa đặt (ex03)
CREATE TABLE r09.notes (id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY, tenant_id int NOT NULL, body text NOT NULL);
INSERT INTO r09.notes (tenant_id, body) VALUES (1, 'ghi chú A'), (1, 'ghi chú A2'), (2, 'ghi chú B');
ALTER TABLE r09.notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON r09.notes USING (tenant_id = current_setting('app.tenant_id')::int);
GRANT SELECT, INSERT, UPDATE, DELETE ON r09.notes TO r09_app;

-- (3) payments + view báo cáo của owner (ex04) + quyền cho role hỗ trợ (ex05)
CREATE TABLE r09.payments (id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY, tenant_id int NOT NULL, amount numeric(12,2) NOT NULL);
INSERT INTO r09.payments (tenant_id, amount) VALUES (1, 10), (1, 20), (2, 30), (2, 40), (3, 50);
ALTER TABLE r09.payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON r09.payments
  USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int)
  WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int);
CREATE VIEW r09.payment_totals AS SELECT tenant_id, count(*) AS n_payments, sum(amount) AS total FROM r09.payments GROUP BY tenant_id;
GRANT SELECT, INSERT, UPDATE, DELETE ON r09.payments TO r09_app;
GRANT SELECT ON r09.payments, r09.payment_totals TO r09_support;
GRANT SELECT ON r09.payment_totals TO r09_app;

-- (4) khuôn bảng cho schema-per-tenant (ex06)
CREATE TABLE r09.tpl_invoices (
  id         int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer   text NOT NULL,
  amount     numeric(12,2) NOT NULL CHECK (amount >= 0),
  created_at timestamptz NOT NULL DEFAULT now());
