# R08 · Bài tập (Concurrency bugs)

Tất cả chạy trên **DB `lab`** schema `r08` (script chấm tự chạy `setup.sql`; có hàm `r08.transfer` mẫu cho ex06). Bài 2–6 mô phỏng **nhiều session đồng thời bằng `dblink`** (bộ chấm tự `CREATE EXTENSION IF NOT EXISTS dblink`, cần quyền superuser như user `postgres` của workspace): session nền giữ transaction mở trong lúc session chính chạy hàm của bạn. Bài 1, 7, 8 tự đối chiếu (có số đo thật).
Viết hàm vào `answers/exNN.sql`; hàm được tạo trong schema `r08`. Tự chấm: `bash tools/check.sh lessons/R08-concurrency-bugs 02`.

**Pass:** tái hiện và sửa đúng 3 bug (ex02 oversell, ex04 double booking, ex05 write skew) cộng ex01 (tái hiện lost update) và ít nhất 2 trong ex03, ex06, ex07, ex08.

---

## 🟢 Cơ bản

### ex01 · Tái hiện lost update (tự đối chiếu)
`r08.counters(id, n)`: hai request cùng "cộng 1" vào `n` của dòng 1. Tự tái hiện bằng hai cửa sổ `psql` (hoặc hai kết nối): cách (a) mỗi bên `SELECT n` rồi `UPDATE … SET n = <số vừa đọc + 1>`; cách (b) mỗi bên `UPDATE … SET n = n + 1`. Ghi vào `answers/ex01.md`: `n` cuối cùng của mỗi cách và vì sao khác nhau.
Đối chiếu: `solutions/ex01.md` và chạy `solutions/ex01.sql` (tự động hai session).

---

## 🟡 Kết hợp

### ex02 · Không bán quá tồn kho (oversell)
Viết hàm `r08.reserve(p_product int, p_qty int) RETURNS boolean`: nếu đủ hàng thì trừ `products.stock` và thêm một dòng vào `r08.orders`, trả `true`; không đủ hoặc sản phẩm không tồn tại thì trả `false` (không lỗi, không đơn). Phải đúng khi 4 khách cùng tranh 2 hàng cuối. Bảng `products` có `CHECK (stock >= 0)` nhưng kết quả đúng phải là `false`, không phải lỗi `23514`.
- Kiểm tra bằng bộ test (tuần tự và 4 session đồng thời)

### ex03 · Optimistic locking
Viết hàm `r08.update_price(p_id int, p_expected_version int, p_new_price numeric) RETURNS boolean` cập nhật `price` và tăng `version` của `r08.products` **chỉ khi** `version` hiện tại bằng `p_expected_version`; trả `true` nếu ghi được, `false` nếu có người đã sửa xen vào hoặc không có sản phẩm.
- Kiểm tra bằng bộ test

---

## 🔴 Thực tế

### ex04 · "Hai khách đặt cùng một phòng cùng giờ" (double booking)
Team vận hành báo hai khách cùng được xác nhận phòng 1 lúc 9:30–10:30. `r08.bookings(room_id, during tstzrange, status)`: thêm **ràng buộc** để database không bao giờ cho hai đặt chỗ `confirmed` chồng khoảng thời gian trong cùng phòng, dù hai request đến cùng lúc. Đặt chỗ `cancelled` không được cản ai; đặt liền kề (kết thúc 10:00, bắt đầu 10:00) là hợp lệ.
- Kiểm tra bằng bộ test (kể cả hai session chèn chồng nhau)

### ex05 · "Không còn bác sĩ nào trực" (write skew)
`r08.doctors(id, name, on_call)`: quy tắc bất biến là luôn còn **ít nhất một** bác sĩ `on_call = true`. Viết hàm `r08.go_off_call(p_doc int) RETURNS boolean`: đặt bác sĩ về `on_call = false` và trả `true`; nếu bác sĩ đó là người trực cuối cùng, hoặc đã không trực, trả `false`. Phải giữ quy tắc kể cả khi hai bác sĩ cùng xin nghỉ tại cùng thời điểm.
- Kiểm tra bằng bộ test (tuần tự và hai session đồng thời)

### ex06 · "Chuyển tiền hai chiều làm treo" (deadlock)
Hàm `r08.transfer(p_from, p_to, p_amount)` đã có trong schema (trừ tiền rồi cộng tiền; có `pg_sleep(0.5)` giữa hai bước để giả lập xử lý nghiệp vụ chậm). Khi hai khách chuyển cho nhau cùng lúc thì một trong hai bị hủy với `40P01`. Viết lại bằng `CREATE OR REPLACE FUNCTION r08.transfer(…)` (cùng chữ ký, **giữ nguyên bước `pg_sleep(0.5)`**) để không còn deadlock và cả hai khoản chuyển đều được áp dụng.
- Kiểm tra bằng bộ test (A chuyển 1 → 2, B chuyển 2 → 1 chồng lên nhau)

### ex07 · SERIALIZABLE và retry (tự đối chiếu)
Chạy lại kịch bản ex05 mà **không có khóa nào**, hai lần: ở `REPEATABLE READ` rồi ở `SERIALIZABLE` (hai session). Ghi vào `answers/ex07.md`: kết quả mỗi lần (còn bao nhiêu bác sĩ trực, lỗi gì nếu có), ứng dụng phải làm gì khi gặp lỗi đó, và so sánh với cách khóa ở ex05.
Đối chiếu: `solutions/ex07.md` và chạy `solutions/ex07.sql`.

---

## 📏 ex08 · Câu hỏi quy mô: một dòng nóng
Bộ đếm lượt xem: `UPDATE counters SET n = n + 1 WHERE id = 1` chạy từ nhiều client. So với 16 dòng phân mảnh, mỗi request cộng vào một dòng ngẫu nhiên.
1. **Dự đoán** (ghi vào `answers/ex08.md`): TPS của hai cách với 1, 4, 16 client. Cách nào tăng theo số client? Độ trễ trung bình của dòng nóng ở 16 client là bao nhiêu lần so với 1 client?
2. Đo bằng `pgbench -n -T 10 -c <client> -j <thread> -f script.sql lab` (chạy trong container: `docker exec -it sql-practice-pg bash`); thử cả `PGOPTIONS="-c synchronous_commit=off"`.
3. Giải thích điểm gãy và nêu hai cách khác để đếm lượt xem mà không tạo dòng nóng.

Lời giải và số đo thật: `solutions/ex08.md`.
