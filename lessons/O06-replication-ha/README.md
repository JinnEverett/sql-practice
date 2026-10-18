# O06 · Replication & HA: streaming, lag, failover, logical

Đọc khoảng 10 phút. Mọi số đo lấy trên Postgres 18.6, chạy bằng **các container tạm** `postgres:18` trong một mạng Docker riêng (không đụng `sql-practice-pg`): máy 8 CPU, các container cùng một máy nên **độ trễ mạng gần bằng 0** (cận dưới, không đại diện cho kết nối giữa hai vùng). Ví dụ SQL của bài 1–3 chạy trên `lab`, schema `o06` (`setup.sql`, dữ liệu cố định).

## Mục tiêu: sau buổi này bạn làm được
- Dựng một replica streaming bằng Docker và đọc được trạng thái của nó trên primary.
- Đo và hiểu **replica lag**, vì sao đọc từ replica có thể "không thấy dữ liệu vừa ghi" và cách xử lý.
- Làm một lần failover và biết **split-brain** là gì, cách đưa primary cũ trở lại.
- Phân biệt streaming (physical) và logical replication, và biết logical **không** làm gì.

---

## 1. Streaming replication (physical)
Primary ghi mọi thay đổi vào **WAL**; replica kết nối, nhận WAL qua mạng và **replay** nó, nên là một bản sao từng byte của cả cụm. Replica mở ở chế độ `hot_standby` thì **đọc được, không ghi được**:
```
ERROR:  cannot execute INSERT in a read-only transaction
```
Dựng nhanh (chi tiết và đầu ra: `solutions/ex04.md`):
```bash
# primary: role + cho phép kết nối replication (pg_hba), wal_level mặc định là replica
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'repl';
echo "host replication replicator all scram-sha-256" >> $PGDATA/pg_hba.conf
# replica: sao chép cả cụm rồi khởi động ở chế độ standby (-R tạo standby.signal + primary_conninfo, -C -S tạo replication slot)
pg_basebackup -h primary -U replicator -D $PGDATA -R -X stream -C -S replica1
```
- **Bất đồng bộ (mặc định):** `COMMIT` trả về ngay khi WAL xuống đĩa *của primary*; mất primary có thể mất giao dịch chưa tới replica.
- **Đồng bộ:** `synchronous_standby_names` + `synchronous_commit` (`remote_write`, `on` = flush ở replica, `remote_apply` = đã replay, đọc được ngay). Mỗi mức an toàn hơn thêm một vòng mạng vào mỗi `COMMIT`, và nếu replica đồng bộ chết thì primary **chờ** (phải có ≥ 2 ứng viên).
- **Replication slot** bắt primary giữ WAL cho đến khi replica nhận: tránh replica "đói" WAL, nhưng replica chết lâu thì WAL **chất đầy đĩa primary**. Đặt `max_slot_wal_keep_size`, và theo dõi.
- Replica cần `max_connections` **≥** primary.

## 2. Replica lag
`pg_stat_replication` (chạy trên primary) cho thấy WAL đi qua bốn chặng:
```
sent_lsn → write_lsn → flush_lsn → replay_lsn        (gửi → ghi vào OS → fsync → áp dụng)
write_lag / flush_lag / replay_lag                    (thời gian; NULL khi replica nhàn rỗi và đã bắt kịp)
```
`pg_wal_lsn_diff(a, b)` trả byte giữa hai LSN. **Lag byte** (khối lượng WAL chưa xử lý) và **lag thời gian** (độ cũ của dữ liệu) là hai thước khác nhau (ex01, ex02).

Đã đo:

| Tình huống | Lag byte | `replay_lag` |
|---|---|---|
| nhàn rỗi | 0 | 2,4 ms |
| `pgbench -c8` (950 tps, ghi) | 0 – 4,3 KB | 3,3 – 71,9 ms |
| nạp 4 triệu dòng một câu lệnh (≈ 538 MB WAL trong ≈ 27 s) | tối đa ≈ 7,8 MB | tối đa 0,78 s |
| replica **chặn replay** (xung đột với truy vấn dài, mục 4) | 111 MB | **≈ 5 s** (đúng bằng `max_standby_streaming_delay`) |

(Lấy mẫu mỗi ~2 s nên đỉnh thật có thể cao hơn; mạng nội bộ nên con số này là cận dưới.)

## 3. Read-your-writes: đọc từ replica có thể không thấy dữ liệu vừa ghi
Đã tái hiện bằng `pg_wal_replay_pause()`: ghi trên primary (commit ở LSN `0/B575138`), đọc ngay trên replica:
```
replica: SELECT count(*) WHERE v = 'vừa-ghi'   -> 0         (replay_lsn = 0/B575088 < 0/B575138)
... pg_wal_replay_resume() ...                  -> 1
```
Các cách xử lý (đánh đổi tăng dần):
1. **Đọc primary** ngay sau khi ghi (sticky: vài giây sau ghi, hoặc cho mọi request của phiên đó). Đơn giản, nhưng tải dồn về primary.
2. **Token LSN:** sau khi ghi lấy `pg_current_wal_lsn()`, lưu vào phiên; chỉ đọc từ replica có `pg_last_wal_replay_lsn() >= token`, không thì đọc primary (ex03). Chính xác, cần router. (PG18 chưa có `WAIT FOR LSN` ở phía replica; chờ bằng cách thăm dò.)
3. **`synchronous_commit = remote_apply`:** ghi xong là replica đã thấy, đổi lại mỗi commit chậm hơn và phụ thuộc replica.
4. Chấp nhận dữ liệu cũ cho màn hình không cần mới (báo cáo, danh sách công khai).

## 4. Xung đột trên replica: truy vấn dài vs VACUUM
Primary dọn dòng chết bằng VACUUM; WAL ghi lại việc đó; nếu một truy vấn dài trên replica còn cần các dòng ấy thì replay **phải chọn**: chờ hoặc hủy truy vấn. Đã đo (`max_standby_streaming_delay = 5s`):

| `hot_standby_feedback` | Điều xảy ra |
|---|---|
| `off` (mặc định) | replay **dừng ≈ 5 s** (111 MB WAL dồn lại), rồi truy vấn bị hủy: `ERROR: canceling statement due to conflict with recovery` |
| `on` | không bị hủy, replay không dừng; nhưng VACUUM trên primary báo `150000 are dead but not yet removable` cho tới khi replica nhả snapshot: **primary phình** |

Truy vấn dài trên replica là cái giá phải trả bằng một trong hai: bị hủy hoặc primary phình. Cách tốt: replica riêng cho báo cáo với `max_standby_streaming_delay` lớn (chấp nhận lag), hoặc `hot_standby_feedback = on` và giám sát bloat.

## 5. Failover và split-brain
**Promote** biến replica thành primary: `SELECT pg_promote()` (đo: ≈ 0,5 s kể cả chi phí `docker exec`; timeline chuyển 1 → 2). Phần *khó* của HA không phải promote mà là:
1. **Phát hiện** primary chết thật (không phải mạng chập chờn) và chỉ chọn **một** replica.
2. **Fencing:** đảm bảo primary cũ **không còn nhận ghi**. Nếu nó sống lại tự tin mình là primary, bạn có **split-brain**: hai nơi cùng nhận ghi, dữ liệu rẽ nhánh. Đã tái hiện: sau failover, primary cũ khởi động lại và nhận `INSERT` id 1003 trong khi primary mới nhận id 1024; hai bảng `ryw` khác nhau.
3. **Đưa primary cũ về làm replica:** `pg_rewind` kéo lại phần rẽ nhánh (đo: rẽ tại `0/B578A90` trên timeline 1, chép 179 MB / 351 MB), `-R` ghi cấu hình standby. Gặp hai bẫy thật ở bước rejoin: (a) `pg_hba.conf` của primary mới chưa cho user đó kết nối **replication** (`no pg_hba.conf entry for replication connection`); (b) **replication slot không được sao chép**, nên slot `replica1` phải tạo lại trên primary mới (`replication slot "replica1" does not exist`).
4. **Ứng dụng tìm được primary mới** (VIP, DNS, proxy).

Làm tay thế này dễ sai. Công cụ như **Patroni** (khái niệm, không dựng trong bài): các node giữ một "leader key" trong kho phân tán (etcd/Consul/ZooKeeper) với TTL; node nào giữ được khóa thì là primary; mất khóa thì tự hạ xuống; kèm watchdog làm fencing. Managed service (RDS, Cloud SQL...) làm hộ phần này.

## 6. Logical replication
Thay vì sao chép byte WAL, logical **giải mã WAL thành thay đổi mức dòng** và gửi theo mô hình **publication / subscription**, chọn được từng bảng (hoặc cột/dòng). Cần `wal_level = logical` ở publisher.

| | Physical (streaming) | Logical |
|---|---|---|
| Sao chép | cả cụm, từng byte | bảng được chọn, thay đổi mức dòng |
| Replica ghi được? | không | **có** (bảng nhận có thể ghi riêng) |
| DDL | theo tự động | **không** tự sao chép |
| Sequence | theo tự động | **không** sao chép |
| Khác phiên bản/OS | không (cùng major) | **có** (dùng để nâng cấp ít downtime) |
| Dùng cho | HA, đọc mở rộng | tích hợp, CDC, nâng cấp, tách một phần dữ liệu |

Đã tái hiện các bẫy (ex07): `UPDATE` bảng **không có khóa chính/replica identity** trên publisher bị từ chối; sequence ở subscriber không đổi (publisher `nextval` = 102, subscriber = 1); thêm cột ở publisher mà chưa thêm ở subscriber làm apply worker **kẹt** (`target relation "public.items" is missing replicated column: "note"`) và slot trên publisher **giữ WAL** (46 MB sau 300 000 dòng); ghi trùng khóa ở subscriber gây `conflict=insert_exists` và worker thoát/khởi động lại liên tục.

## Đo bằng gì
`pg_stat_replication` (primary), `pg_stat_wal_receiver` / `pg_last_wal_replay_lsn()` / `pg_is_in_recovery()` (replica), `pg_replication_slots`, `pg_stat_subscription`, `pg_wal_lsn_diff()`, `pg_walfile_name()` (đọc timeline), log server.

## Bẫy hay gặp
1. Gọi là "HA" khi chưa có fencing hay chưa thử failover.
2. Đọc replica ngay sau ghi mà không có chiến lược read-your-writes.
3. Replication slot không ai dùng làm đầy đĩa primary.
4. Truy vấn dài trên replica bị hủy (hoặc primary phình vì `hot_standby_feedback`).
5. Coi `replay_lag = NULL` là "lỗi" (nó là nhàn rỗi, đã bắt kịp).
6. Cho rằng logical replication sao chép DDL, sequence hay tự giải quyết xung đột.
7. Bảng không có khóa chính trong publication.
8. Sau failover quên tạo lại slot/`pg_hba`, hoặc chạy lại primary cũ mà không `pg_rewind`.
9. Sequence có khoảng trống sau failover (do ghi WAL trước một đoạn giá trị): bình thường, đừng dựa vào ID liên tục.

## Postgres-specific
- So sánh LSN bằng kiểu `pg_lsn`, **không** so sánh dạng chuỗi (`'0/9000000' > '0/10000000'` là đúng với text nhưng sai với LSN; ex03).
- MySQL dùng binlog (logical theo dòng/câu lệnh); streaming của Postgres là sao chép WAL (vật lý), logical là tùy chọn riêng.
- `WAIT FOR LSN` (chờ replay trên replica) không có ở 18.6: đã thử, báo `syntax error at or near "WAIT"`.
