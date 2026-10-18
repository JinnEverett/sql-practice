-- sai: thêm `true` nhưng quên nullif → chuỗi rỗng vẫn gây lỗi 22P02
ALTER POLICY tenant_isolation ON r09.notes USING (tenant_id = current_setting('app.tenant_id', true)::int);
