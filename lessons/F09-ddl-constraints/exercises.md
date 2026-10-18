# F09 · Bài tập

Tất cả chạy trên DB **`lab`**, schema **`f09`**. Mỗi bài viết các lệnh DDL (và DML nếu cần) vào `answers/exNN.sql`.
Script chấm tự chạy lại `setup.sql`, chạy bài của bạn trong `BEGIN … ROLLBACK`, rồi chạy một **bộ test hành vi**:
chèn dòng hợp lệ (phải thành công) và dòng vi phạm (phải bị chặn, đúng loại lỗi). Tên constraint/index bạn tự đặt.

```bash
# reset schema f09 về ban đầu (khi thử tay trong psql)
MSYS_NO_PATHCONV=1 docker exec -i sql-practice-pg psql -U postgres -d lab -X -q < lessons/F09-ddl-constraints/setup.sql
# tự chấm bài NN
bash tools/check.sh lessons/F09-ddl-constraints 01
```

Mã lỗi Postgres hay gặp: `23502` NOT NULL · `23503` FK · `23505` UNIQUE · `23001` vi phạm ON DELETE RESTRICT · `23514` CHECK · `23P01` EXCLUDE · `428C9` ghi vào cột GENERATED ALWAYS.

**Pass:** đạt 8/10 bài. Tiêu chí trong ROADMAP: thiết kế được schema có ràng buộc đúng.

---

## 🟢 Cơ bản

### ex01 · Bảng khách hàng
Tạo bảng `f09.customers`:
- `id` kiểu `bigint`, **tự sinh**, là khóa chính. Ứng dụng **không được phép** tự điền `id` (cố điền thì phải lỗi).
- `email` text **bắt buộc**, **không trùng**.
- `full_name` text bắt buộc. `phone` text tùy chọn.
- `created_at` timestamptz bắt buộc, **mặc định** là thời điểm chèn.

Bộ test sẽ thử: chèn không có `id` → được, `id` và `created_at` tự có giá trị · chèn có `id` → lỗi `428C9` · trùng email → `23505` · thiếu `full_name` hoặc `email` → `23502`.

### ex02 · Bảng sản phẩm có kiểm tra dữ liệu
Tạo bảng `f09.products`:
- `id` int tự sinh, khóa chính (cho phép điền tay).
- `sku` text bắt buộc, không trùng, đúng định dạng **2 chữ in hoa, gạch ngang, 4 chữ số**, ví dụ `AB-0001`. Chuỗi như `ab-0001`, `AB-001`, `XAB-00011` đều phải bị chặn.
- `name` text bắt buộc.
- `price` tiền VND có 2 chữ số lẻ (`numeric(12,2)`), bắt buộc, **không âm**.
- `stock` int bắt buộc, mặc định 0, không âm.
- `status` text bắt buộc, mặc định `'draft'`, chỉ nhận `'draft'`, `'active'`, `'archived'`.

### ex03 · Đơn hàng và khóa ngoại
Đã có sẵn `f09.c_customers(id, name)` và `f09.c_products(id, name)`. Tạo:
- `f09.c_orders`: `id` int tự sinh (khóa chính), `customer_id` int bắt buộc tham chiếu `c_customers`, `created_at` timestamptz bắt buộc mặc định `now()`. **Không được xóa** khách khi khách còn đơn.
- `f09.c_order_items`: `order_id` tham chiếu `c_orders`, `line_no` smallint, `product_id` tham chiếu `c_products`, `quantity` int **> 0**. Khóa chính là cặp `(order_id, line_no)`. **Xóa đơn thì tự xóa các dòng hàng** của đơn đó. **Không được xóa** sản phẩm đã có trong đơn.
- Tạo index cho các cột khóa ngoại **chưa có index dùng được** (Postgres không tự tạo index cho FK).

---

## 🟡 Kết hợp

### ex04 · Dọn email trùng rồi khóa lại
`f09.legacy_users(id, email, created_at)` có email trùng nhau nếu bỏ khác biệt hoa/thường và khoảng trắng đầu/cuối. Hãy viết **các lệnh** để:
1. Xóa bản trùng: mỗi nhóm giữ bản **`created_at` sớm nhất**, hòa thì **`id` nhỏ nhất**.
2. Chuẩn hóa mọi email còn lại về dạng `lower(trim(email))`.
3. Thêm ràng buộc để **từ nay** không thể chèn email trùng theo nghĩa trên. Ví dụ đã có `an@x.vn` thì chèn `' AN@x.vn '` phải bị chặn (lỗi nhóm `23…`).
- Kỳ vọng: còn **4 dòng** với `id` = 1, 4, 5, 6.

### ex05 · Cột tính sẵn (generated column)
Tạo bảng `f09.order_lines`:
- `id` int tự sinh khóa chính; `quantity` int bắt buộc > 0; `unit_price` numeric(12,2) bắt buộc ≥ 0;
- `discount_pct` numeric(5,2) bắt buộc, mặc định 0, trong khoảng **0 đến 100**;
- `line_total` numeric(14,2) **do database tự tính** = `quantity × unit_price × (1 − discount_pct/100)`, làm tròn 2 chữ số. Ứng dụng không ghi được vào cột này, và nó tự cập nhật khi `quantity` đổi.
- Ví dụ: `quantity 2, unit_price 100000, discount 10` → `line_total = 180000.00`.

### ex06 · Khuyến mãi: ràng buộc giữa nhiều cột
Tạo bảng `f09.promotions`: `id` int tự sinh khóa chính, `code` text bắt buộc không trùng, `percent` int, `amount` numeric(12,2), `starts_at` timestamptz bắt buộc, `ends_at` timestamptz.
Quy tắc nghiệp vụ:
- Mỗi khuyến mãi có **đúng một** trong hai kiểu giảm: theo phần trăm **hoặc** theo số tiền. Không được có cả hai, cũng **không được thiếu cả hai**.
- `percent` (nếu có) từ 1 đến 90. `amount` (nếu có) > 0.
- `ends_at` để trống nghĩa là vô thời hạn. Nếu có thì phải **sau** `starts_at` (bằng nhau cũng không được).

### ex07 · Mỗi khách một địa chỉ mặc định
Tạo bảng `f09.addresses(id int tự sinh khóa chính, user_id int bắt buộc, line text bắt buộc, is_default boolean bắt buộc mặc định false)`.
Một khách có **bao nhiêu địa chỉ cũng được**, nhưng **tối đa một** địa chỉ `is_default = true`.

### ex08 · Sơ đồ nhân sự
Tạo bảng `f09.employees`:
- `id` int khóa chính (điền tay), `full_name` text bắt buộc;
- `manager_id` int tham chiếu **chính bảng này**, để trống được (sếp lớn nhất không có quản lý). Một người **không thể là quản lý của chính mình**. Khi xóa một quản lý, nhân viên dưới quyền **vẫn còn**, chỉ mất thông tin quản lý;
- `work_email` text **tùy chọn**, nhưng nếu có thì không được trùng. **Nhiều người chưa có email** là bình thường.

---

## 🔴 Thực tế

### ex09 · Đặt phòng họp
Công ty muốn database **tự chặn** lỗi đặt trùng phòng, thay vì tin vào code ứng dụng. Tạo:
- `f09.rooms(id int khóa chính, name text bắt buộc)`. Tên phòng không trùng, **không phân biệt hoa/thường** (`Phòng A` và `phòng a` là một).
- `f09.bookings`: `id` int tự sinh khóa chính, `room_id` tham chiếu `rooms` (bắt buộc), `booked_by` text bắt buộc, `starts_at` và `ends_at` timestamptz bắt buộc, `status` text bắt buộc mặc định `'confirmed'`, chỉ nhận `'confirmed'` hoặc `'cancelled'`.
- Quy tắc: `ends_at > starts_at`. **Hai lịch `confirmed` của cùng một phòng không được chồng giờ nhau.** Lịch nối tiếp (9:00–10:00 và 10:00–11:00) là hợp lệ. Lịch đã `cancelled` không chặn ai. Phòng khác nhau thì không liên quan.
- Gợi ý: đọc mục "Exclusion constraint" trong README.

### ex10 · Đổi kiểu cột giá đang lưu dạng text
`f09.imports(id, sku, price text)` lưu giá từ file Excel: `'1.200.000đ'`, `'350000'`, `'89.000 đ'`, `' 2.500.000 '`, `'0'`. Hãy viết lệnh **đổi kiểu cột `price` sang `numeric(12,2)` ngay tại chỗ** (giữ tên cột, không tạo bảng mới), chuyển đúng giá trị (`'1.200.000đ'` → `1200000.00`), rồi thêm ràng buộc `price >= 0`.
- Kỳ vọng sau khi chạy: tổng `price` của 5 dòng là `4139000.00`.

---

## 📏 Bonus (tùy chọn): `ALTER TABLE` trên bảng 1 triệu dòng
Tạo bảng thử trên DB `lab`, rồi **dự đoán trước** (ghi vào comment) thời gian của từng lệnh: tức thì (vài ms) hay phải ghi lại cả bảng (vài giây)? Đo bằng `\timing on`.
```sql
CREATE TABLE f09.big AS SELECT g AS id, now() AS created_at FROM generate_series(1, 1000000) g;
ALTER TABLE f09.big ADD COLUMN a int DEFAULT 0;                          -- (1)
ALTER TABLE f09.big ADD COLUMN b timestamptz DEFAULT clock_timestamp();  -- (2)
ALTER TABLE f09.big ALTER COLUMN id TYPE bigint;                         -- (3)
ALTER TABLE f09.big ADD CONSTRAINT big_a_chk CHECK (a >= 0);             -- (4)
```
Câu hỏi: lệnh nào ghi lại cả bảng (rewrite)? Ở bảng 10 triệu dòng thì sao? Trong lúc rewrite, các session khác đọc/ghi bảng này được không? Lời giải: `solutions/ex11.md`.
