CREATE POLICY tenant_isolation ON o01.orders
  FOR ALL TO o01_tenant_app
  USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int);
