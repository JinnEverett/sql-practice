# R09 · Bài tập (Multi-tenancy & RLS)

Tất cả chạy trên **DB `lab`** schema `r09` (script chấm tự chạy `setup.sql`: 3 tenant, `customers`, `invoices`, `notes`, `payments`, view `payment_totals`, bảng khuôn `tpl_invoices`, hai role `r09_app` và `r09_support`).
Các bài RLS kiểm tra bằng cách `SET ROLE r09_app` và đặt tenant qua `set_config('app.tenant_id', '…', true)`, đúng như ứng dụng thật. Viết DDL vào `answers/exNN.sql`; bộ chấm chạy rồi ROLLBACK.
Tự chấm: `bash tools/check.sh lessons/R09-multitenancy-rls 01`. Bài 7 là câu hỏi quy mô (tự đối chiếu).

**Pass:** 5/6 bài chấm tự động; ROADMAP: "RLS chặn đúng truy cập chéo" = ex02 + ex03 + ex04 đúng.

---

## 🟢 Cơ bản

### ex01 · Hóa đơn không được trỏ sang khách của tenant khác
`r09.invoices(tenant_id, customer_id, …)` và `r09.customers(id, tenant_id, …)`. Hiện tạo được hóa đơn của tenant 1 trỏ vào khách của tenant 2. Thêm ràng buộc để database chặn việc đó (lỗi `23503`), không phá dữ liệu hiện có.
- Kiểm tra bằng bộ test

---

## 🟡 Kết hợp

### ex02 · Cô lập tenant bằng RLS
Bật RLS cho `r09.invoices` sao cho một phiên của ứng dụng (`r09_app`) với `app.tenant_id = N` chỉ **thấy** hóa đơn của tenant N, không **ghi** được hóa đơn mang tenant khác (cả INSERT lẫn đổi `tenant_id` khi UPDATE; lỗi `42501`), và `UPDATE`/`DELETE` lên dòng của tenant khác không tác động gì.
- Kiểm tra bằng bộ test

### ex03 · Policy không được làm hỏng query khi thiếu tenant
`r09.notes` đã bật RLS với policy `tenant_isolation` dùng `current_setting('app.tenant_id')::int`. Khi phiên chưa đặt `app.tenant_id` (hoặc đặt rỗng), query báo lỗi thay vì trả 0 dòng. Sửa policy để trong các trường hợp đó **không lỗi, trả 0 dòng, và không ghi được**.
- Kiểm tra bằng bộ test (chưa đặt biến; biến rỗng; tenant 1, 2 vẫn đúng)

### ex04 · Đóng nốt lỗ hổng ở view
`r09.payments` đã có RLS đúng. Nhưng `r09.payment_totals` (view tổng hợp theo tenant, tạo bởi chủ bảng) cho `r09_app` thấy tổng của **mọi** tenant. Sửa để ứng dụng chỉ thấy tổng của tenant hiện tại.
- Kiểm tra bằng bộ test

---

## 🔴 Thực tế

### ex05 · "Nhân viên hỗ trợ cần xem dữ liệu mọi tenant (chỉ đọc)"
Team CS cần role `r09_support` đọc được `r09.payments` của mọi tenant để xử lý khiếu nại, nhưng không được ghi, và **không được làm lộ thêm dữ liệu** cho ứng dụng thường (`r09_app` vẫn chỉ thấy tenant của mình). Thêm cấu hình cần thiết.
- Kiểm tra bằng bộ test

### ex06 · Tạo tenant mới theo kiểu schema-per-tenant
Viết hàm `r09.provision_tenant(p_slug text) RETURNS void`: tạo schema `t_<slug>` chứa bảng `invoices` có cấu trúc y hệt `r09.tpl_invoices` (cột, PK, CHECK, identity), cấp cho `r09_app` quyền dùng schema và `SELECT/INSERT/UPDATE/DELETE` bảng. Gọi lại cùng slug không được lỗi và không mất dữ liệu. `p_slug` chỉ gồm chữ thường, số và `_`, bắt đầu bằng chữ cái, dài ≤ 41 ký tự; slug sai định dạng (kể cả cố tình chèn `;`) phải bị từ chối với lỗi `22023` (`invalid_parameter_value`) trước khi chạy bất cứ lệnh DDL nào.
- Kiểm tra bằng bộ test

---

## 📏 ex07 · Câu hỏi quy mô: RLS có làm chậm không?
Bảng `inv(tenant_id, created_at, amount)` 100 tenant lệch (tenant 1 chiếm 30%). Query: tổng tiền tháng 3 của tenant hiện tại.
1. **Dự đoán** (ghi vào `answers/ex07.md`) ở N = 100k và 1M: (a) không RLS + `WHERE tenant_id` viết tay; (b) RLS đúng; cả hai khi chưa có index và khi có index `(tenant_id, created_at)`. RLS tốn thêm bao nhiêu %? Nếu policy gọi một hàm plpgsql không khai báo gì thêm, nhanh hay chậm hơn, vì sao?
2. Tự dựng dữ liệu (xem `solutions/ex07.sql`, đổi 100000 thành 1000000) và đo bằng `EXPLAIN (ANALYZE, BUFFERS)` **dưới role `r09_app`**.
3. Giải thích điểm gãy; nêu khi nào RLS không đủ cho tenant lớn.

Lời giải và số đo thật: `solutions/ex07.md`.
