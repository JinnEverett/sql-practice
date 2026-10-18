-- sai: policy chỉ cho SELECT → INSERT/UPDATE không được phép (không có policy) hoặc, nếu thêm USING cho ALL, thiếu kiểm tra khi ghi tenant_id khác
ALTER TABLE r09.invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_read ON r09.invoices FOR SELECT USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::int);
CREATE POLICY tenant_write ON r09.invoices FOR INSERT WITH CHECK (true);
