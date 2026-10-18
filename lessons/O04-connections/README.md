# O04 · Connections: chi phí kết nối, max_connections, PgBouncer

Đọc khoảng 10 phút. Số đo trên Postgres 18.6 (container `sql-practice-pg`, 8 CPU, `max_connections = 100`) và PgBouncer 1.26.0. Thí nghiệm dùng DB tạm `o04_bench` (pgbench scale 10); ví dụ SQL của bài 1–3 chạy trên `lab`, schema `o04` (`setup.sql`).

## Mục tiêu: sau buổi này bạn làm được
- Giải thích vì sao **mở kết nối Postgres đắt** và đo được nó.
- Tính số kết nối thực sự dùng được, và biết lỗi `too many clients already` đến từ đâu.
- Chọn cỡ pool hợp lý thay vì "càng nhiều càng tốt".
- Cấu hình PgBouncer ở chế độ transaction và biết **cái gì sẽ hỏng** khi bật nó.

---

## 1. Một kết nối là một process
Postgres chạy **một process hệ điều hành cho mỗi kết nối** (không phải thread). Mở kết nối = `fork` + bắt tay + xác thực (SCRAM) + khởi tạo backend; đóng đi là bỏ hết.

| Phép đo (`pgbench -S`, 4 client) | Kết quả |
|---|---|
| Kết nối bền, truy vấn đơn giản | **12 283 tps**, trễ 0,33 ms |
| Mở kết nối mới cho **mỗi** giao dịch (`-C`, unix socket) | **428 tps** (chậm ≈ 29×), mở kết nối mất 4,6 ms |
| Như trên nhưng qua TCP + SCRAM | **129 tps**, mở kết nối mất 15,3 ms |

Truy vấn tốn 0,3 ms mà bắt tay tốn 5–15 ms: nếu ứng dụng mở kết nối cho mỗi request, bạn trả giá gấp 15–50 lần công việc thật. Đây là lý do mọi ứng dụng cần **pool**.

Bộ nhớ: mỗi backend nhàn rỗi có RSS ≈ 17,8 MB trong phép đo (RSS tính cả trang bộ nhớ chia sẻ, đừng nhân lên), riêng bộ nhớ cục bộ của backend chỉ ≈ 1,4 MB (`pg_backend_memory_contexts`). Phần đắt là lúc **chạy**: mỗi node sort/hash của mỗi truy vấn có thể xin tới `work_mem` (O05), nên 500 kết nối cùng chạy truy vấn nặng có thể xin nhiều hơn RAM.

## 2. max_connections và lỗi "too many clients"
```sql
SHOW max_connections;                      -- 100
SHOW superuser_reserved_connections;       -- 3: chỉ superuser dùng được
SHOW reserved_connections;                 -- 0 (từ PG16): chỉ role pg_use_reserved_connections dùng được
```
Kết nối dùng được cho ứng dụng = `max_connections − superuser_reserved_connections − reserved_connections` (ở đây **97**). Hết chỗ thì:
```
FATAL:  sorry, too many clients already
```
(đã tái hiện: 120 client `pgbench` vào server `max_connections = 100`). Đừng chữa bằng cách tăng `max_connections` thật to: nó đổi lấy bộ nhớ chia sẻ lớn hơn (bảng khóa, mảng process dùng chung) và nhiều kết nối cùng tranh CPU hơn; mà thông lượng thì không tăng (xem mục 3). Cũng cần `max_connections` ở **replica ≥ primary** (O06).

Xem ai đang chiếm chỗ:
```sql
SELECT state, count(*) FROM pg_stat_activity WHERE backend_type = 'client backend' GROUP BY state ORDER BY 2 DESC;
SELECT application_name, count(*) FROM pg_stat_activity GROUP BY 1 ORDER BY 2 DESC;   -- dặn app đặt application_name!
```
Tổng kết nối = **số bản chạy × cỡ pool mỗi bản**. 6 pod × pool 20 = 120 > 97 là cách phổ biến nhất để tự bắn vào chân (ex02).

## 3. Cỡ pool: nhiều hơn không có nghĩa là nhanh hơn
Đo `pgbench -S` trên máy 8 CPU (client pgbench cũng ăn CPU của cùng máy):

| Số kết nối | 1 | 2 | 4 | 8 | 16 | 32 | 64 |
|---|---|---|---|---|---|---|---|
| tps (select-only) | 5 161 | 8 239 | 13 275 | 23 163 | 29 718 | 34 971 | 35 506 |
| tps (TPC-B, ghi) | 338 | – | 843 | 1 115 | 1 704 | 1 771 | 2 126 |

Thông lượng tăng gần tuyến tính tới ≈ số core, rồi **đi ngang** (select-only: từ 32 lên 64 kết nối chỉ +1,5%). Thêm kết nối chỉ thêm hàng đợi, bộ nhớ và tranh chấp. Quy tắc ngón tay cái: số kết nối **đang hoạt động** đáng dùng là vài lần số core (2–4×), thấp hơn nếu workload I/O thấp, cao hơn nếu truy vấn chờ I/O hoặc chờ khóa nhiều. Đo trên workload của bạn.

## 4. PgBouncer: nhiều client, ít kết nối server
PgBouncer đứng giữa, nhận **hàng trăm client** (mỗi client chỉ vài KB) và dồn vào một **pool nhỏ kết nối server**.

| `pool_mode` | Trả kết nối server về pool khi | Dùng khi |
|---|---|---|
| `session` | client ngắt kết nối | cần mọi tính năng session; ít lợi ích khi client sống lâu |
| `transaction` | `COMMIT`/`ROLLBACK` | đa số ứng dụng web/API (mặc định nên thử) |
| `statement` | mỗi câu lệnh xong | hiếm; cấm transaction nhiều câu |

Cấu hình tối thiểu (file đầy đủ: `pgbouncer/pgbouncer.ini`):
```ini
[databases]
o04_bench = host=sql-practice-pg port=5432 dbname=o04_bench pool_size=10
[pgbouncer]
pool_mode = transaction
max_client_conn = 500      ; client nhận được
default_pool_size = 10     ; kết nối server cho mỗi cặp (db, user)
auth_type = scram-sha-256
```
Đã đo (`pgbench -S`, qua TCP):

| Tình huống | Trực tiếp | Qua PgBouncer |
|---|---|---|
| 300 client bền | **lỗi `too many clients`** | **9 358 tps**, 0 lỗi |
| mở kết nối mới mỗi giao dịch (`-C`, 4 client) | 129 tps | 236 tps (≈ 1,8×) |
| 4 client bền | 11 371 tps | 7 900 tps (**chậm hơn ≈ 30%**) |

PgBouncer **không miễn phí**: thêm một chặng mạng và một process đơn luồng. Nó thắng khi có nhiều client hơn kết nối server cần dùng hoặc khi client hay mở/đóng kết nối; nó thua nhẹ khi ít client bền.

## 5. Bẫy của transaction mode
Vì hai transaction liên tiếp của cùng một client có thể chạy trên **hai kết nối server khác nhau**, và hai client có thể **dùng chung một** kết nối server, mọi thứ có "trạng thái session" đều hỏng hoặc rò rỉ. Đã tái hiện bằng pool nhỏ (ex07):

| Thứ dùng | Chuyện xảy ra | Cách đúng |
|---|---|---|
| `SET statement_timeout = …` | client B thấy giá trị client A đặt (cùng backend) | `SET LOCAL` trong transaction, hoặc đặt ở cấp role/DB |
| `pg_advisory_lock` cấp session | khóa dính vào kết nối server, người khác thừa hưởng | `pg_advisory_xact_lock` |
| `PREPARE … ; EXECUTE …` (SQL) | `prepared statement "q1" does not exist` khi rơi sang kết nối khác | prepared statement ở mức giao thức (`max_prepared_statements`, tính năng có từ 1.21; mặc định 200 trên bản 1.26 đã đo) hoặc tắt prepare ở driver |
| `LISTEN/NOTIFY`, bảng `TEMP`, cursor `WITH HOLD` | mất/lẫn trạng thái | kết nối riêng ở `session` mode |

## Đo bằng gì
`pgbench` (`-S`, `-C`, `-c`, `-j`, `-T`), `pg_stat_activity`, `pg_settings`, `SHOW POOLS` / `SHOW STATS` / `SHOW CONFIG` (console PgBouncer, DB `pgbouncer`), `ps` đo RSS backend.

## Bẫy hay gặp
1. Tăng `max_connections` thay vì thêm pool.
2. Quên rằng tổng = bản chạy × cỡ pool (chưa kể worker, cron, migration, admin).
3. Pool lớn hơn số core nhiều lần và tin là "nhanh hơn".
4. Bật transaction mode mà ứng dụng dùng `SET`, advisory lock session, `PREPARE` SQL.
5. Để `idle in transaction` giữ kết nối (O03).
6. Không đặt `application_name` nên không biết ai chiếm kết nối.
7. Dùng PgBouncer cho cả client ít và bền rồi ngạc nhiên vì chậm đi.

## Postgres-specific
- MySQL dùng thread cho mỗi kết nối, nên chi phí khác; Postgres dựa vào pooler ngoài (PgBouncer, pgcat, Odyssey…) hoặc pool trong ứng dụng.
- Từ PG16 có `reserved_connections` bên cạnh `superuser_reserved_connections`.
- Một số dịch vụ managed (RDS Proxy, Supabase, Neon) đã gắn sẵn pooler: vẫn áp dụng các bẫy ở mục 5.
