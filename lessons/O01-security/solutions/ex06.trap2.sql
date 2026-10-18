ALTER TABLE o01.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON o01.orders
  FOR ALL TO o01_tenant_app
  USING (tenant_id = current_setting('app.tenant_id')::int);
