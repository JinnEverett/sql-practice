CREATE ROLE o01_support NOLOGIN;
GRANT USAGE ON SCHEMA o01 TO o01_support;
GRANT SELECT ON o01.customers TO o01_support;
CREATE VIEW o01.v_customers_public AS SELECT id, name, tenant_id FROM o01.customers;
GRANT SELECT ON o01.v_customers_public TO o01_support;
