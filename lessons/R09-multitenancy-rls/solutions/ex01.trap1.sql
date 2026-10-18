-- sai: có UNIQUE nhưng FK vẫn chỉ theo customer_id
ALTER TABLE r09.customers ADD CONSTRAINT customers_id_tenant_uq UNIQUE (id, tenant_id);
