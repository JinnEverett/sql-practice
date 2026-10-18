# P08 · Locks & deadlocks

Đọc khoảng 10 phút. Ví dụ chạy trên `lab.p08` (`setup.sql`), Postgres 18.6. Bài cần nhiều session: mở nhiều cửa sổ `psql`, hoặc để script chấm dựng session B ở nền (cách làm giống P06: dòng `-- >>> B`).

## Mục tiêu: sau buổi này bạn làm được
- Nói lệnh nào lấy lock mức bảng nào và lệnh nào chặn lệnh nào.
- Dùng khóa dòng đúng: `FOR UPDATE`, `FOR NO KEY UPDATE`, `FOR SHARE`, `NOWAIT`, `SKIP LOCKED`.
- Tái hiện, đọc log và **sửa deadlock** bằng thứ tự khóa nhất quán.
- Tránh "bão" do hàng đợi lock của `ALTER TABLE` bằng `lock_timeout`; dùng advisory lock cho tác vụ chạy một mình.

---

## 1. Lock mức bảng
Mọi lệnh đều lấy một lock mức bảng. Đo bằng `pg_locks` trong chính transaction:

| lệnh | lock mức bảng | chặn gì |
|---|---|---|
| `SELECT` | `AccessShareLock` | chỉ `AccessExclusive` |
| `SELECT … FOR UPDATE` | `RowShareLock` | `Exclusive`, `AccessExclusive` |
| `INSERT/UPDATE/DELETE` | `RowExclusiveLock` | `Share` trở lên (kể cả `CREATE INDEX` thường) |
| `VACUUM`, `CREATE INDEX CONCURRENTLY` | `ShareUpdateExclusiveLock` | chính nó và các DDL |
| `CREATE INDEX` | `ShareLock` | mọi ghi (SELECT vẫn chạy) |
| `ALTER TABLE ADD COLUMN`, `DROP`, `TRUNCATE`, `VACUUM FULL` | `AccessExclusiveLock` | **mọi thứ kể cả SELECT** |

Điểm cốt lõi: `UPDATE` không chặn `UPDATE` khác ở mức **bảng**; chỉ khi cùng **dòng** mới chờ.

## 2. Khóa dòng
Khóa dòng không nằm trong `pg_locks` mà trong header tuple (`xmax`); người chờ hiện là "chờ transaction X".
| | nghĩa |
|---|---|
| `FOR UPDATE` | sắp sửa hoặc xóa dòng; chặn mọi khóa dòng khác |
| `FOR NO KEY UPDATE` | sắp sửa nhưng không đổi khóa; `UPDATE` thường dùng mức này; **không chặn** `FOR KEY SHARE` của khóa ngoại |
| `FOR SHARE` / `FOR KEY SHARE` | chặn người khác sửa/xóa; `KEY SHARE` là cái FK lấy khi INSERT bảng con |
| `NOWAIT` | báo lỗi `55P03` ngay thay vì chờ |
| `SKIP LOCKED` | bỏ qua dòng đang bị khóa: nền tảng của hàng đợi (ex02, ex07) |

## 3. Deadlock
Hai transaction giữ khóa mà bên kia cần. Postgres kiểm tra sau `deadlock_timeout` (1 s) và **hủy một bên** (`40P01`). Sửa tận gốc bằng **thứ tự khóa nhất quán** (ex03, ex06); retry chỉ là lưới an toàn. `log_lock_waits = on` ghi cả những lần chờ quá `deadlock_timeout`.

## 4. Hàng đợi lock của ALTER TABLE
Lock chờ theo hàng đợi **công bằng**: nếu `ALTER TABLE` (AccessExclusive) đang chờ một truy vấn dài, mọi `SELECT` mới xếp sau nó và cũng bị chặn, dù `ALTER` chưa làm gì. Một báo cáo 30 giây + `ALTER` có thể làm site đứng 30 giây (ex04). Cách chữa: `SET lock_timeout = '1s'` trước DDL và retry; chạy DDL lúc ít tải; ưu tiên DDL "nhẹ" (`ADD COLUMN` không default hoặc default hằng không rewrite bảng từ Postgres 11; `CREATE INDEX CONCURRENTLY`).

## 5. Advisory lock
Khóa do ứng dụng đặt tên (số nguyên), không gắn với bảng/dòng: `pg_try_advisory_lock(42)` (không chờ), `pg_advisory_lock(42)` (chờ), `pg_try_advisory_xact_lock` (tự nhả cuối transaction). Dùng cho "chỉ một bản cron chạy tại một thời điểm" (ex05). Khóa mức session giữ tới khi disconnect: cẩn thận với connection pool (transaction pooling không giữ được).

## Bẫy hay gặp
1. `ALTER TABLE` trên bảng đang có truy vấn dài, không `lock_timeout`.
2. Khóa nhiều dòng/bảng theo thứ tự khác nhau ở các đường mã khác nhau.
3. Transaction giữ khóa rồi gọi API ngoài/chờ người dùng.
4. `SELECT … FOR UPDATE` không kèm `ORDER BY`/`LIMIT` khóa nhiều hơn cần.
5. `pg_advisory_lock` (chờ) cho job cron: các bản chạy chồng lên nhau chờ vô hạn.
6. Nhầm khóa ngoại: INSERT bảng con lấy `FOR KEY SHARE` trên dòng cha; bảng con thiếu index FK làm xóa/sửa cha phải quét cả bảng con khi chờ khóa (F09, P02).

## Đo bằng gì
- `pg_locks`, `pg_stat_activity` (`wait_event_type = 'Lock'`), `pg_blocking_pids(pid)`, log server (`log_lock_waits`), `pgbench` (ex07).
- Giới hạn phép đo: các bài chấm dùng `sleep` để ép thứ tự xen kẽ (1–4 giây); máy chậm có thể cần tăng. tps ở ex07 phụ thuộc máy.
