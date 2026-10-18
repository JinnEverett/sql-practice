# P06 · Transactions & isolation

Đọc khoảng 10 phút. Mọi ví dụ chạy trên `lab.p06` (`setup.sql`) với Postgres 18.6. Bài cần **hai session**: mở hai cửa sổ `psql` (hoặc để script chấm dựng session B giúp, xem cuối file).

## Mục tiêu: sau buổi này bạn làm được
- Giải thích ACID bằng hành vi cụ thể của Postgres (WAL, MVCC), không phải thuộc lòng định nghĩa.
- Chọn isolation level theo anomaly cần chặn; biết Postgres chặn nhiều hơn chuẩn SQL ở `REPEATABLE READ`.
- Tái hiện và sửa: **non-repeatable read, phantom read, lost update, write skew**.
- Viết transaction đúng với lỗi: `SAVEPOINT`, retry khi gặp `40001` (serialization failure) và `40P01` (deadlock).

---

## 1. ACID, nhìn từ Postgres
| | nghĩa là | Postgres làm bằng |
|---|---|---|
| **A**tomicity | tất cả hoặc không gì cả | mỗi lệnh sửa tạo phiên bản dòng mới; `ROLLBACK` chỉ việc coi các phiên bản đó là vô hiệu (không phải "hoàn tác từng dòng") |
| **C**onsistency | ràng buộc luôn đúng khi commit | `CHECK`, `FK`, `UNIQUE` được kiểm tra; **nghiệp vụ nằm ngoài** (ex06) do bạn thiết kế |
| **I**solation | các transaction đồng thời không "thấy nhau" tùy mức | MVCC snapshot + khóa dòng (P07, P08) |
| **D**urability | commit rồi thì còn dù crash | WAL được `fsync` trước khi trả "COMMIT"; `synchronous_commit = off` đánh đổi độ bền lấy tốc độ |

`BEGIN … COMMIT` gom lệnh vào một transaction. Một **lệnh lỗi làm cả transaction aborted**: mọi lệnh sau bị từ chối (`current transaction is aborted…`) cho tới `ROLLBACK`; `COMMIT` lúc này thực chất là ROLLBACK. `SAVEPOINT s` / `ROLLBACK TO s` quay lại giữa chừng mà giữ phần trước (ex02).

## 2. Isolation level trong Postgres
Chọn bằng `BEGIN ISOLATION LEVEL …` hoặc `SET TRANSACTION ISOLATION LEVEL …` (phải là lệnh đầu của transaction).

| level | snapshot | chặn |
|---|---|---|
| `READ UNCOMMITTED` | = READ COMMITTED (Postgres không có dirty read) | dirty read |
| `READ COMMITTED` (**mặc định**) | **mỗi lệnh** một snapshot mới | dirty read |
| `REPEATABLE READ` | **một snapshot cho cả transaction**, chụp ở lệnh đầu tiên | + non-repeatable read, + phantom (Postgres chặn cả phantom, mạnh hơn chuẩn) |
| `SERIALIZABLE` | như RR + theo dõi phụ thuộc đọc/ghi (SSI) | + write skew và mọi bất thường khác: kết quả như chạy tuần tự |

Anomaly (xem ex03–ex06):
- **Non-repeatable read**: đọc cùng dòng hai lần, giá trị khác vì giao dịch khác commit giữa chừng.
- **Phantom**: chạy cùng điều kiện hai lần, ra tập dòng khác.
- **Lost update**: hai bên đọc cùng giá trị, mỗi bên ghi lại giá trị tự tính; bên sau xóa mất cập nhật của bên trước.
- **Write skew**: hai bên đọc cùng một tập, mỗi bên sửa một dòng khác nhau, và kết hợp lại vi phạm quy tắc (ví dụ "luôn có ≥ 1 bác sĩ trực").

Hai cái bẫy đặc trưng của Postgres:
1. `UPDATE` ở `READ COMMITTED` gặp dòng đang bị giao dịch khác sửa thì **chờ**, rồi đọc lại phiên bản mới nhất của dòng (re-check điều kiện `WHERE`), không dùng snapshot cũ. Vì thế `SET balance = balance + 30` an toàn, còn `SET balance = 130` thì không.
2. `REPEATABLE READ`/`SERIALIZABLE` có thể báo **`ERROR: could not serialize access…` (SQLSTATE 40001)**: không phải bug, ứng dụng phải **chạy lại cả transaction**.

## 3. Khóa tường minh
- `SELECT … FOR UPDATE` khóa dòng như sắp sửa; `FOR SHARE` chặn người khác sửa nhưng cho đọc. Giao dịch khác muốn sửa phải **chờ** tới khi bạn commit. (Chi tiết: P08.)
- `SELECT * FROM doctor WHERE on_call FOR UPDATE` khóa mọi dòng trong tập, chặn write skew nếu mọi nơi cùng làm vậy và UPDATE kiểm tra lại điều kiện.

## 4. Retry
Với `REPEATABLE READ`/`SERIALIZABLE`/deadlock, ứng dụng phải bắt `40001` và `40P01` rồi chạy lại toàn bộ transaction (từ `BEGIN`). Chi phí đo ở ex07: dưới tranh chấp cao có >50% giao dịch phải chạy lại.

## Bẫy hay gặp
1. Đọc rồi ghi lại số tính ở app (`SET balance = 130`): lost update ở mọi level yếu.
2. Nghĩ `READ UNCOMMITTED` đọc được dữ liệu chưa commit trong Postgres.
3. Dùng `SERIALIZABLE` mà không có vòng retry.
4. Transaction giữ mở lâu (đợi người dùng bấm nút): giữ khóa và chặn vacuum dọn dòng chết (P07).
5. Quy tắc nghiệp vụ liên dòng (≥ 1 bác sĩ trực, tổng tiền ≥ 0) không thể bằng `CHECK`: cần khóa hoặc SERIALIZABLE.

## Cách script chấm dựng hai session
Bài làm của A là một script có dòng `-- >>> B` đúng như vậy: check chạy phần trước dòng đó, rồi **bật session B ở nền** (một tiến trình `psql` riêng, cập nhật dữ liệu), chờ 1 giây, chạy phần sau của A, `COMMIT`. Bạn tự làm như vậy bằng hai cửa sổ `psql`.

## Đo bằng gì
- Hai cửa sổ `psql`; `SHOW transaction_isolation;`; `pg_stat_activity` (cột `wait_event`); `pgbench` (ex07).
- Giới hạn phép đo: các bài chấm dùng `sleep` 1–2 giây để ép thứ tự xen kẽ; trên máy rất chậm có thể cần tăng. Số tps ở ex07 phụ thuộc máy (container dùng chung 4 nhân với mọi thứ khác).
