# R10 · Bài tập (Migrations không downtime)

Tất cả chạy trên **DB `lab`** schema `r10` (script chấm tự chạy `setup.sql`: `orders` 20 000 dòng, `users` có email trùng và một index INVALID, `orders2`, `parent`/`child`).
Viết các lệnh DDL/DML vào `answers/exNN.sql`. Bài chấm bằng **trạng thái catalog và dấu vết DDL** (bộ chấm dựng một *event trigger* ghi lại thứ tự các lệnh DDL của bạn, nên kết quả đúng nhưng đi đường chặn người dùng vẫn bị chấm sai). Bài 8 dùng `dblink` để giữ một truy vấn đọc chạy lâu và một truy vấn đến sau (bộ chấm tự `CREATE EXTENSION IF NOT EXISTS dblink`, cần quyền superuser).
Một số bài (4, 8) KHÔNG bọc trong transaction vì `CONCURRENTLY` không chạy trong transaction block; bài 3 gọi thủ tục bằng `CALL` ngoài transaction.
Tự chấm: `bash tools/check.sh lessons/R10-zero-downtime-migrations 01`. Bài 5 và 9 tự đối chiếu số đo.

**Pass:** ROADMAP "kế hoạch migration không downtime" = ex05 (kế hoạch) + 6/8 bài còn lại.

---

## 🟢 Cơ bản

### ex01 · Thêm cột mà không viết lại bảng
Thêm cột `priority integer NOT NULL DEFAULT 0` vào `r10.orders` (20 000 dòng, trên production là hàng chục triệu). Mọi dòng cũ có `priority = 0`. Không được viết lại bảng và không được `UPDATE` dòng nào.
- Kiểm tra bằng bộ test (`relfilenode` không đổi, `xmin` của mọi dòng không đổi)

### ex02 · Thêm `NOT NULL` an toàn
`r10.orders.customer_ref` hiện nullable nhưng mọi dòng đều có giá trị. Biến nó thành `NOT NULL` mà không giữ khóa ACCESS EXCLUSIVE trong lúc quét bảng. Không để lại ràng buộc thừa.
- Kiểm tra bằng bộ test (trạng thái cuối và dấu vết DDL phải đi qua ràng buộc `NOT VALID`)

---

## 🟡 Kết hợp

### ex03 · Backfill theo lô
Cột `r10.orders.status_code` (smallint) mới thêm, đang NULL. Viết `PROCEDURE r10.backfill_status(p_batch int)` điền theo `status`: `pending → 1, paid → 2, shipped → 3, delivered → 4, cancelled → 5`. Mỗi lô tối đa `p_batch` dòng và là **một transaction riêng** (không giữ khóa/WAL của cả bảng); chạy lại được (idempotent); trả về khi không còn dòng NULL.
- Kiểm tra bằng bộ test (`CALL r10.backfill_status(5000)` rồi kiểm số transaction qua `xmin`)

### ex07 · Thêm khóa ngoại an toàn
`r10.child(parent_id)` chưa có FK tới `r10.parent(id)` (dữ liệu hiện tại hợp lệ). Thêm FK `child_parent_fk` mà không chặn ghi trong lúc quét dữ liệu cũ.
- Kiểm tra bằng bộ test (FK cuối cùng phải ở trạng thái đã xác thực; dấu vết DDL phải đi qua `NOT VALID`)

---

## 🔴 Thực tế

### ex04 · "Deploy báo lỗi duplicate key và query chậm hẳn"
Team báo: migration `CREATE UNIQUE INDEX CONCURRENTLY users_email_uq ON r10.users (email)` hôm qua báo lỗi `duplicate key`, từ đó mọi INSERT vào `users` chậm hơn. Xử lý: (1) với mỗi email trùng, giữ dòng có `updated_at` mới nhất (trùng thì `id` lớn nhất), xóa các dòng còn lại; (2) dọn index hỏng; (3) tạo lại `users_email_uq` UNIQUE mà không chặn ghi. Không chạy trong transaction.
- Kiểm tra bằng bộ test (còn id 2, 3, 6, 7; không còn index INVALID; index UNIQUE hợp lệ; dựng bằng `CONCURRENTLY`)

### ex06 · Đổi tên cột `total` → `amount_vnd` (expand/contract)
`r10.orders2` có `total` (code cũ đang dùng) và `amount_vnd` (cột mới, đang trống). Trong giai đoạn chuyển tiếp hai phiên bản code cùng chạy: code cũ chỉ ghi `total`, code mới chỉ ghi `amount_vnd`. Viết trigger để hai cột luôn bằng nhau mọi lúc (cả INSERT và UPDATE, cả hai chiều, kể cả giá trị NULL) và backfill các dòng có sẵn.
- Kiểm tra bằng bộ test

### ex08 · "ALTER chạy giờ cao điểm làm cả bảng đứng"
Bạn cần `ALTER TABLE r10.orders ADD COLUMN note text` trong lúc một báo cáo đang đọc bảng (giữ khóa 1.5 giây). `ALTER` trần sẽ xếp hàng chờ báo cáo và chặn mọi truy vấn thường đến sau. Viết đoạn migration (một khối `DO`) thêm cột `note` sao cho truy vấn thường đến sau không phải chờ quá 0.6 giây: dùng `lock_timeout` ngắn (≤ 500 ms) kèm vòng retry có giới hạn.
- Kiểm tra bằng bộ test (đo thời gian chờ của truy vấn đến sau, và `lock_timeout` hiệu lực lúc ALTER chạy)

### ex05 · Kế hoạch đổi `id` từ `integer` sang `bigint` (tự đối chiếu)
Bảng `orders` 500 triệu dòng, `id integer` sắp chạm 2.1 tỉ, có 3 bảng con tham chiếu và hệ thống chạy 24/7. Viết `answers/ex05.md`: kế hoạch từng bước (lệnh, loại khóa, thời gian dự kiến), thứ tự deploy code, cách kiểm tra từng bước, và đường lui. Tự dựng bản nhỏ để thử (N = 100 000).
Đối chiếu: `solutions/ex05.md` (kèm số đo thật của cách ngây thơ) và chạy `solutions/ex05.sql`.

---

## 📏 ex09 · Câu hỏi quy mô: DDL tốn bao lâu và chặn ai?
Với bảng 100k / 1M / 5M dòng.
1. **Dự đoán** (ghi vào `answers/ex09.md`): thời gian và mức chặn (đọc? ghi?) của: `ADD COLUMN … DEFAULT 0`; `ADD COLUMN … DEFAULT random()`; `ALTER COLUMN TYPE bigint`; `CREATE INDEX` thường; `CREATE INDEX CONCURRENTLY`; `SET NOT NULL` trực tiếp; `NOT VALID` + `VALIDATE` + `SET NOT NULL`. Thao tác nào không đổi theo N?
2. Tự đo bằng `\timing` và một cửa sổ `psql` thứ hai chạy `SELECT`/`INSERT` ngay lúc DDL đang chạy (xem `solutions/ex09.sql`).
3. Giải thích khác biệt giữa "thời gian chạy" và "thời gian chặn".

Lời giải và số đo thật: `solutions/ex09.md`.
