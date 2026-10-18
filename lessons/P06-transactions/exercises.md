# P06 · Bài tập (Transactions & isolation)

Tất cả chạy trên DB **`lab`** schema `p06` (script chấm tự chạy `setup.sql`). Bài làm là **script SQL** trong `answers/exNN.sql`.
**Bài có 2 session (ex03–ex06):** bài làm là transaction của session A, có **một dòng riêng `-- >>> B`** chia script làm 2 đoạn. Check chạy đoạn 1, bật session B ở nền (hành động của B ghi trong đề), chờ 1–2 giây, chạy đoạn 2. Hãy **tự tái hiện anomaly bằng hai cửa sổ `psql`** trước khi viết (mức mặc định sẽ cho anomaly xuất hiện; xem `solutions/exNN.md` ghi lại kết quả thật nếu bạn muốn đối chiếu sau khi làm).
Tự chấm: `bash tools/check.sh lessons/P06-transactions 03`.

**Pass:** "Tái hiện được 3 anomaly bằng 2 session": ex03–ex06 (mỗi bài gồm tái hiện + sửa), tổng ≥ 6/7 bài, gồm ex06.

---

## 🟢 Cơ bản

### ex01 · Chuyển tiền và thu phí
`p06.acct`: tài khoản 1 có 100, tài khoản 2 có 50, `CHECK (balance >= 0)`. Viết script: trừ 80 của tài khoản 1, cộng 80 cho tài khoản 2, rồi thu phí 30 của tài khoản 1 (bước này sẽ vi phạm CHECK vì 1 chỉ còn 20). Sau khi chạy, hai số dư phải **về nguyên** 100 và 50: không được chuyển tiền "nửa chừng".

### ex02 · Nhập lô một phần
`p06.sku(code PK, name)` đã có `A1`. Nhập 3 dòng trong **một transaction**: `B2`, `A1` (trùng, sẽ lỗi), `C3`. Sau khi commit: `B2` và `C3` được ghi, `A1` giữ nguyên bản gốc ('ban đầu'). Không dùng `ON CONFLICT`.

---

## 🟡 Kết hợp (hai session)

### ex03 · Đọc hai lần cùng một số
Session A đọc `balance` của tài khoản 1 hai lần trong một transaction (ghi vào `p06.reads` với `step` = 1, 2), giữa hai lần **B cộng 50 cho tài khoản 1 và commit**. Hai lần đọc của A phải **bằng nhau**, trong khi cập nhật của B vẫn phải được commit (balance cuối = 150). Điền mức isolation (hoặc cách khóa) phù hợp.
```sql
BEGIN ISOLATION LEVEL ???;
INSERT INTO p06.reads SELECT 1, balance FROM p06.acct WHERE id = 1;
-- >>> B
INSERT INTO p06.reads SELECT 2, balance FROM p06.acct WHERE id = 1;
COMMIT;
```

### ex04 · Hai người cùng cộng tiền
A đọc `balance` của tài khoản 1 (100) để hiển thị, rồi cộng 30. Giữa chừng **B cộng 50 và commit**. Sau cả hai, balance phải là **180** (không mất cập nhật nào). Viết bước ghi của A (và nếu cần, sửa bước đọc).
```sql
BEGIN;
SELECT balance FROM p06.acct WHERE id = 1;
-- >>> B
-- bước ghi của A: cộng 30
COMMIT;
```

### ex05 · Đếm đơn mở hai lần
A đếm số đơn `status = 'open'` trong `p06.ticket` hai lần trong một transaction (ghi `p06.reads`, `step` 1, 2); giữa hai lần **B chèn một đơn `open` mới và commit**. Hai lần đếm của A phải **bằng nhau** (2 và 2) còn đơn mới của B vẫn được commit. Chọn mức isolation **yếu nhất trong Postgres** làm được việc này.

---

## 🔴 Thực tế

### ex06 · "Hết người trực"
Bệnh viện: quy tắc nghiệp vụ **luôn có ít nhất 1 bác sĩ trực** (`p06.doctor.on_call`). Team báo: tối qua cả hai bác sĩ An và Bình cùng bấm "nghỉ trực" cùng lúc, ứng dụng kiểm tra "còn ≥ 2 người trực" đều đúng với từng người, rồi cả hai nghỉ → 0 người trực.
Mô hình: bài làm là script của **một** bác sĩ `:me` (`1` hoặc `2`): đoạn 1 kiểm tra, đoạn 2 nghỉ trực. Check chạy **hai bản của script đồng thời** (A với `:me = 1`, B với `:me = 2`), B đọc cùng lúc với A trước khi cả hai ghi. Sau đó phải còn **ít nhất 1 người trực** và có ít nhất 1 người đã nghỉ (hệ thống vẫn làm được việc). Chấp nhận cả cách "một bên bị từ chối với lỗi serialization" lẫn cách "khóa cho tuần tự".
```sql
BEGIN ISOLATION LEVEL ???;
SELECT count(*) FROM p06.doctor WHERE on_call;    -- app thấy 2 nên cho nghỉ
-- >>> B
UPDATE p06.doctor SET on_call = false WHERE id = :me;
COMMIT;
```
Gợi ý: có hai họ giải pháp; giải thích khác biệt và nhược điểm của từng họ trong file `answers/ex06.md`.

---

## 📏 Câu hỏi quy mô

### ex07 · Giá của isolation level khi tranh chấp
Mô hình: 8 client chạy giao dịch read-modify-write (đọc rồi `UPDATE v = v + 1`) lên một dòng ngẫu nhiên trong (a) 4 dòng nóng, (b) 1 000 dòng. **Dự đoán trước**: tps và tỉ lệ giao dịch lỗi ở `READ COMMITTED`, `REPEATABLE READ`, `SERIALIZABLE` cho từng trường hợp; và retry tốn bao nhiêu. Sau đó đo bằng `pgbench` (script trong `solutions/ex07.md`). Đối chiếu `solutions/ex07.md`.
