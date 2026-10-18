-- sai: thiếu TO r09_support → policy áp dụng cho mọi role, tenant nào cũng thấy tất cả
CREATE POLICY support_read ON r09.payments FOR SELECT USING (true);
