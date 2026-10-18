-- sai: chỉ 3 trong 4 remainder → một số tenant không có chỗ chèn
CREATE TABLE r12.tenant_logs (tenant_id int NOT NULL, id bigint NOT NULL, msg text, PRIMARY KEY (tenant_id, id)) PARTITION BY HASH (tenant_id);
CREATE TABLE r12.tenant_logs_0 PARTITION OF r12.tenant_logs FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE r12.tenant_logs_1 PARTITION OF r12.tenant_logs FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE r12.tenant_logs_2 PARTITION OF r12.tenant_logs FOR VALUES WITH (MODULUS 4, REMAINDER 2);
