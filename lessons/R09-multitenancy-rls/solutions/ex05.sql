-- db: lab
-- mode: check
-- reset
-- Giải thích: nhân viên hỗ trợ (role r09_support) cần ĐỌC dữ liệu mọi tenant. Các policy cùng lệnh (SELECT) là PERMISSIVE nên được OR với nhau:
--   thêm policy riêng `FOR SELECT TO r09_support USING (true)` mở quyền đọc cho role này mà không đụng tới policy tenant_isolation của ứng dụng.
--   `TO r09_support` rất quan trọng: thiếu nó policy áp dụng cho PUBLIC và mọi tenant thấy tất cả. Quyền ghi của support không có (chỉ GRANT SELECT, và không có policy ghi).
-- Bẫy: policy USING (true) không có TO → mở cho cả role ứng dụng; dùng BYPASSRLS cho role hỗ trợ (bypass cả khi ghi, ngoài tầm kiểm soát policy).
CREATE POLICY support_read ON r09.payments FOR SELECT TO r09_support USING (true);
