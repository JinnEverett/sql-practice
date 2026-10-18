-- db: lab
-- mode: check
-- reset
-- Giải thích: FK `invoices.customer_id → customers(id)` chỉ đảm bảo khách TỒN TẠI, không đảm bảo khách thuộc CÙNG tenant với hóa đơn: một bug ở ứng dụng
--   (hoặc kẻ tấn công đổi customer_id) tạo được hóa đơn của tenant 1 trỏ vào khách của tenant 2 — rò rỉ chéo tenant ngay ở tầng dữ liệu.
--   Sửa: FK ghép (customer_id, tenant_id) → customers(id, tenant_id). Postgres yêu cầu cột được tham chiếu có UNIQUE/PK, nên thêm UNIQUE (id, tenant_id)
--   (id đã là PK nên cặp này luôn duy nhất, chỉ để đáp ứng yêu cầu cú pháp).
-- Bẫy: chỉ thêm UNIQUE mà quên đổi FK; FK ghép nhưng thứ tự cột hai vế lệch nhau; cho tenant_id nullable (NULL trong FK ghép MATCH SIMPLE bỏ qua kiểm tra).
ALTER TABLE r09.customers ADD CONSTRAINT customers_id_tenant_uq UNIQUE (id, tenant_id);
ALTER TABLE r09.invoices ADD CONSTRAINT invoices_customer_same_tenant_fk
  FOREIGN KEY (customer_id, tenant_id) REFERENCES r09.customers (id, tenant_id);
