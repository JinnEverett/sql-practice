# R10 · Migrations không downtime

Đọc khoảng 10 phút. Mọi bài chạy trên DB `lab`, schema `r10` (tạo bởi `setup.sql`, bảng `orders` mặc định 20 000 dòng; muốn bảng lớn hơn: `psql -v n=1000000 -f setup.sql`).

## Mục tiêu: sau buổi này bạn làm được
- Biết **loại khóa** mà từng lệnh DDL cần và ai bị chặn (đọc, ghi, cả hai).
- Thêm cột, thêm `NOT NULL`, thêm FK, tạo index trên bảng đang chạy mà không chặn người dùng.
- Backfill bảng lớn theo lô và đổi tên/đổi kiểu cột bằng expand/contract.
- Phòng **hàng đợi khóa** (lock queue) bằng `lock_timeout` + retry.
- Viết kế hoạch migration có số đo và đường lui.

---

## 1. Khóa và thứ nó chặn
| Lệnh | Khóa chính | Chặn SELECT? | Chặn INSERT/UPDATE/DELETE? |
|---|---|---|---|
| `ADD COLUMN` (default hằng), `DROP COLUMN`, `SET NOT NULL` khi đã có CHECK validate | ACCESS EXCLUSIVE, rất ngắn | tích tắc | tích tắc |
| `ALTER COLUMN TYPE` (cần viết lại), `ADD COLUMN` default volatile, `SET NOT NULL` trực tiếp | ACCESS EXCLUSIVE, **suốt lúc viết lại/quét** | **có** | **có** |
| `CREATE INDEX` | SHARE | không | **có** (suốt lúc dựng) |
| `CREATE INDEX CONCURRENTLY` | SHARE UPDATE EXCLUSIVE | không | không |
| `ADD CONSTRAINT … NOT VALID`; `VALIDATE CONSTRAINT` | ngắn; SHARE UPDATE EXCLUSIVE | không | không |
| `ADD FOREIGN KEY` (không NOT VALID) | SHARE ROW EXCLUSIVE trên cả hai bảng | không | **có** (suốt lúc quét) |
Số đo thật ở ex09: ở 5M dòng, `ALTER COLUMN TYPE` chặn đọc+ghi 8.6 giây, `CREATE INDEX` chặn ghi 3.1 giây (đọc vẫn chạy), `VALIDATE CONSTRAINT` quét 0.34 giây mà không chặn ai.

## 2. Các công thức an toàn
- **Thêm cột:** `ADD COLUMN c type NOT NULL DEFAULT <hằng>` từ Postgres 11 là tức thì, không viết lại bảng (ex01). Default volatile (`random()`, `gen_random_uuid()`, `clock_timestamp()`) viết lại cả bảng: thêm cột nullable không default, đặt default cho dòng MỚI, backfill dòng cũ theo lô, rồi mới ràng buộc.
- **Thêm NOT NULL / CHECK / FK:** thêm ràng buộc `NOT VALID` (ngắn) rồi `VALIDATE CONSTRAINT` (quét không chặn ghi). Với `NOT NULL`: `CHECK (c IS NOT NULL) NOT VALID` → `VALIDATE` → `SET NOT NULL` (bỏ qua quét nhờ CHECK) → `DROP` CHECK (ex02, ex07).
- **Tạo index:** luôn `CREATE INDEX CONCURRENTLY` trên bảng đang có ghi. Nó không chạy trong transaction block, mất gấp ~1.3 lần, và nếu thất bại (dữ liệu vi phạm UNIQUE, bị hủy) để lại index **INVALID** phải `DROP INDEX CONCURRENTLY` rồi tạo lại (ex04). Kiểm tra: `SELECT indexrelid::regclass FROM pg_index WHERE NOT indisvalid`.
- **Backfill:** theo lô khoảng 1 000 – 10 000 dòng, mỗi lô một transaction (`PROCEDURE` + `COMMIT`), chọn theo khóa tăng dần và điều kiện "chưa làm" để chạy lại được; nghỉ giữa các lô nếu replica trễ (ex03).
- **Đổi tên/đổi kiểu cột:** expand → migrate → contract: thêm cột mới, ghi hai chiều bằng trigger (ex06), backfill, chuyển đọc sang cột mới, bỏ cột cũ (ex05). Mỗi bước tương thích với phiên bản code đang chạy ở bước trước và sau.

## 3. Hàng đợi khóa: cạm bẫy lớn nhất
`ALTER TABLE` cần ACCESS EXCLUSIVE nên chờ mọi truy vấn đang chạy trên bảng. **Trong lúc chờ, nó đứng trong hàng đợi khóa và mọi truy vấn đến sau xếp hàng sau nó**, kể cả `SELECT` thường. Một báo cáo chạy 5 phút + một `ALTER` = cả bảng đứng im 5 phút.
- Phiên migration luôn đặt `SET lock_timeout = '200ms'` (hoặc `SET LOCAL`) và **retry** khi gặp `55P03 lock_not_available` (ex08). Cũng nên đặt `statement_timeout` cho các bước dài.
- Đừng chạy migration trong transaction dài; một transaction mở lâu giữ khóa của mọi lệnh đã chạy trong nó.
- Kiểm tra ai đang giữ/đang chờ: `pg_stat_activity` + `pg_locks`/`pg_blocking_pids(pid)` (O03).

## 4. Lập kế hoạch migration
Một kế hoạch tốt có: (1) danh sách bước, mỗi bước ghi loại khóa và thời gian dự kiến theo N (đo trên bản sao dữ liệu thật); (2) bước nào chạy trước khi deploy code, bước nào sau; (3) đường lui cho từng bước (thường chỉ an toàn trước bước "contract"); (4) cách kiểm tra (đếm dòng chưa backfill, `indisvalid`, `convalidated`); (5) giới hạn thời gian và cách dừng giữa chừng.

## Bẫy hay gặp
1. `SET NOT NULL`/`ADD FOREIGN KEY`/`ALTER TYPE` trực tiếp trên bảng lớn.
2. `ALTER` không `lock_timeout` → xếp hàng chặn cả bảng.
3. `CREATE INDEX CONCURRENTLY` thất bại để lại index INVALID rồi không ai dọn.
4. Backfill bằng một UPDATE khổng lồ (bloat, replica lag, khóa lâu).
5. Đổi tên cột bằng `RENAME` khi code cũ vẫn đang chạy.
6. Migration chạy trong một transaction duy nhất với nhiều DDL: giữ mọi khóa tới cuối.

## Postgres-specific
- `ADD COLUMN … DEFAULT <hằng>` tức thì từ Postgres 11 (lưu `attmissingval` trong catalog); `SET NOT NULL` bỏ qua quét nếu có CHECK validate (Postgres 12+); `DROP INDEX CONCURRENTLY` (9.2+); `REINDEX CONCURRENTLY` (12+); `DETACH PARTITION CONCURRENTLY` (14+).
- Event trigger (`CREATE EVENT TRIGGER … ON ddl_command_end`) ghi lại DDL; các bộ chấm của bài này dùng nó để biết bạn đã đi qua trạng thái `NOT VALID` hay đã dùng `CONCURRENTLY`.
- DDL của Postgres chạy trong transaction được (trừ `CONCURRENTLY`): migration lỗi giữa chừng có thể rollback sạch, điều mà MySQL không làm được.
