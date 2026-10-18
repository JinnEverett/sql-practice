# R05 · Bài tập (Lịch sử dữ liệu)

Bài 1–7 chạy trên **DB `lab`** schema `r05` (script chấm tự chạy `setup.sql`); bài 8 trên **`shop_s`**; bài 9 là câu hỏi quy mô (tự đối chiếu).
Bài DDL/trigger viết trực tiếp các lệnh `CREATE …` vào `answers/exNN.sql`; bộ chấm chạy chúng trong transaction rồi ROLLBACK.
Tự chấm: `bash tools/check.sh lessons/R05-history-audit 01`.

**Pass:** 6/8 (8 bài chấm tự động + ex09 tự đối chiếu số đo).

---

## 🟢 Cơ bản

### ex01 · Soft delete đúng cách
`r05.accounts(id, email, name, deleted_at)`. Tạo (1) view `r05.active_accounts(id, email, name)` chỉ gồm tài khoản chưa xóa; (2) ràng buộc để email **không phân biệt hoa/thường** là duy nhất giữa các tài khoản còn hoạt động, nhưng email của tài khoản đã xóa mềm được dùng lại.
- Kiểm tra bằng bộ test

### ex02 · Audit trigger
`r05.products` cần nhật ký: mỗi `INSERT`, `UPDATE`, `DELETE` ghi một dòng vào `r05.product_audit(op, row_id, old_row, new_row, changed_at, changed_by)` (`op` là `'INSERT'`/`'UPDATE'`/`'DELETE'`; `old_row`, `new_row` dạng jsonb của cả hàng; `INSERT` không có `old_row`, `DELETE` không có `new_row`). UPDATE nhiều dòng phải ra nhiều dòng audit.
- Kiểm tra bằng bộ test

---

## 🟡 Kết hợp

### ex03 · Audit gọn: bỏ no-op, chỉ lưu thay đổi
Cải tiến cho `r05.product_audit2(op, row_id, changed_at, changes)`: UPDATE **không đổi giá trị nào** không ghi gì; UPDATE có đổi thì `changes` là jsonb chỉ chứa các cột thay đổi dạng `{"price": {"old": 100000, "new": 120000}}`; INSERT/DELETE lưu cả hàng vào `changes`.
- Kiểm tra bằng bộ test

### ex04 · Danh mục sản phẩm tại một thời điểm
`r05.audit_log(table_name, row_id, op, changed_at, new_row)` ghi mọi thay đổi (INSERT/UPDATE/DELETE; `new_row` NULL khi DELETE) của nhiều bảng. Dựng lại danh mục `products` **tại `2026-04-15 12:00+00`**: sản phẩm còn tồn tại lúc đó với tên và giá.
- Cột: `product_id, name, price` (số) · Sắp xếp: `product_id`
- Kỳ vọng: **2 dòng**, dòng đầu `1 | Tai nghe | 150`

### ex05 · Giá tại thời điểm đặt hàng (SCD2)
`r05.price_history(product_id, price, valid_from, valid_to)` (`valid_to` NULL = đang hiệu lực, khoảng nửa mở `[from, to)`) và `r05.orders(id, product_id, qty, ordered_at)`. Với **mọi đơn** (kể cả đơn đặt trước khi sản phẩm có giá, khi đó giá NULL), tính giá lúc đặt và thành tiền. Chú ý đơn đặt đúng thời điểm đổi giá.
- Cột: `order_id, product_id, qty, unit_price, amount` · Sắp xếp: `order_id`
- Kỳ vọng: **7 dòng**, dòng đầu `1 | 1 | 2 | 100.00 | 200.00`

### ex06 · Đổi giá nguyên tử
Đổi giá sản phẩm 1 thành **160** có hiệu lực từ bây giờ (`now()`) trong `r05.price_history`: đóng dòng đang hiệu lực và mở dòng mới, bằng **một câu lệnh** (dùng CTE data-modifying). Không để lại khoảng trống hay hai dòng "hiện tại".
- Kiểm tra: trạng thái các dòng của sản phẩm 1

---

## 🔴 Thực tế

### ex07 · "Giá bị chồng thời gian"
Team báo: báo cáo doanh thu nhân đôi dòng với sản phẩm 1. `r05.price_history_bad` có hai khoảng giá chồng nhau (sản phẩm 1: giá 100 hết hạn 2026-03-01 nhưng giá 120 đã bắt đầu từ 2026-02-15; sản phẩm 3 có khoảng trống nhưng hợp lệ). Quy tắc xử lý: bản **bắt đầu muộn hơn** thắng, tức cắt `valid_to` của bản trước về `valid_from` của bản sau. Sửa dữ liệu rồi thêm ràng buộc để database tự chặn chồng thời gian từ nay. Không xóa dòng nào, không đổi `valid_from`.
- Kiểm tra bằng bộ test (dữ liệu sau khi sửa và hành vi của ràng buộc: khoảng chồng bị chặn `23P01`, khoảng liền kề được phép)

### ex08 · "Đơn phát sinh sau khi tài khoản bị xóa"
Trên `shop_s`, `users.deleted_at` đánh dấu tài khoản bị xóa mềm. CS báo vẫn thấy đơn đặt SAU thời điểm xóa. Liệt kê các tài khoản đã xóa mềm có ít nhất một đơn tạo vào/sau `deleted_at`, kèm số đơn và tổng tiền sau xóa, và tổng số đơn của tài khoản đó.
- Cột: `user_id, deleted_at, orders_after_deletion, amount_after_deletion, total_orders` · Sắp xếp: `orders_after_deletion` giảm dần, `user_id` tăng dần
- Kỳ vọng: **24 dòng**, dòng đầu `8 | 2026-01-21 16:12:13.31621+00 | 35 | 233571000.00 | 85`

---

## 📏 ex09 · Câu hỏi quy mô: audit trigger khi UPDATE hàng loạt
```sql
UPDATE products SET price = price + 1;   -- toàn bảng, N dòng
```
1. **Dự đoán** (ghi vào `answers/ex09.md`): với N = 100k và 1M, thời gian khi (a) không có trigger, (b) có audit trigger ghi cả hàng như ex02, (c) có audit trigger ghi diff như ex03. Cái nào sinh nhiều WAL nhất? Cái nào tốn CPU nhất? Dung lượng bảng audit sau lệnh?
2. Tự dựng bảng (xem `solutions/ex09.sql`), đo thời gian bằng `\timing`/`EXPLAIN ANALYZE`, WAL bằng chênh lệch `pg_current_wal_lsn()`, dung lượng bằng `pg_total_relation_size`.
3. Giải thích điểm gãy và đề xuất 2 cách giảm chi phí khi cần UPDATE hàng loạt.

Lời giải và số đo thật: `solutions/ex09.md`.
