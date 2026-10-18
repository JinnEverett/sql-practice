# O03 · Monitoring: pg_stat_*, pg_locks, log chậm, auto_explain

Đọc khoảng 10 phút. Ví dụ chạy trên DB `lab` (schema `o03`, `setup.sql`) và `shop_m`. Số đo trên Postgres 18.6, 4 CPU.

## Mục tiêu: sau buổi này bạn làm được
- Tìm **top query tệ nhất** bằng `pg_stat_statements` và biết "tệ" theo tiêu chí nào (tổng thời gian, số block, mean/max).
- Đọc `pg_stat_activity`, `pg_locks` để biết ai đang chạy, ai chờ, ai chặn ai.
- Đọc `pg_stat_user_tables` / `pg_statio_*` để thấy bảng nào bị quét tuần tự, cache hit ra sao.
- Bật log query chậm và `auto_explain`, biết cái giá phải trả.

---

## 1. pg_stat_statements: query nào tốn nhiều nhất
Extension gộp các câu lệnh cùng hình dạng (hằng số → `$1`) và cộng dồn số liệu. Cần `shared_preload_libraries = 'pg_stat_statements'` (đã bật trong `docker-compose.yml`) và `CREATE EXTENSION` trong từng DB.
```sql
SELECT calls, round(total_exec_time) AS total_ms, round(mean_exec_time::numeric, 2) AS mean_ms,
       min_exec_time, max_exec_time, shared_blks_hit + shared_blks_read AS blks, rows, left(query, 80)
FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;
SELECT pg_stat_statements_reset();       -- reset trước/sau khi sửa để đo lại
```
- Sắp theo `total_exec_time` để biết tài nguyên đã tốn; theo `mean_exec_time` để biết query chậm mỗi lần; theo `calls` để biết query nóng; theo `shared_blks_*` để biết I/O (ổn định hơn thời gian).
- **Mean che giấu phân phối**: xem `min_exec_time`, `max_exec_time`, `stddev_exec_time`. Lần chạy nguội (cache lạnh) có thể kéo mean lên 20 lần (ex06).
- `query` đã chuẩn hóa (`$1`). Muốn tham số thật dùng log hoặc `auto_explain`. Các câu trong function/trigger chỉ được ghi riêng nếu `pg_stat_statements.track = all`.
- Thống kê nằm trong shared memory, mất khi crash/restart tùy cấu hình; không phải audit log.

## 2. pg_stat_activity và pg_locks: hệ thống đang làm gì
```sql
SELECT pid, state, wait_event_type, wait_event, pg_blocking_pids(pid) AS blocked_by,
       now() - xact_start AS xact_age, now() - state_change AS in_state, left(query, 60)
FROM pg_stat_activity WHERE datname = current_database() AND pid <> pg_backend_pid();
```
- `state`: `active` (đang chạy), `idle`, **`idle in transaction`** (mở transaction mà không làm gì: giữ khóa, chặn VACUUM).
- `wait_event_type = 'Lock'` + `pg_blocking_pids(pid)` cho biết ai chặn ai (ex04). `pg_locks` cho chi tiết từng khóa (`granted = false` là đang chờ).
- `pg_cancel_backend(pid)` hủy câu lệnh; `pg_terminate_backend(pid)` cắt kết nối. Phòng ngừa: `statement_timeout`, `lock_timeout`, `idle_in_transaction_session_timeout`.

## 3. pg_stat_user_tables, pg_statio_*: bảng và cache
- `seq_scan`, `seq_tup_read`, `idx_scan`, `n_tup_ins/upd/del`, `n_dead_tup`, `last_autovacuum`, `last_autoanalyze`.
- Bảng **lớn** mà `seq_scan` >> `idx_scan` đáng nghi (ex03). Bảng nhỏ quét tuần tự là bình thường.
- `pg_statio_user_tables`: `heap_blks_hit` / `heap_blks_read` cho tỉ lệ cache hit; `pg_stat_database` cho cả DB (`blks_hit`, `blks_read`, `deadlocks`, `temp_files`, `temp_bytes`).
- Bộ đếm cộng dồn từ lần reset cuối (`pg_stat_reset()`); đọc hai thời điểm rồi trừ nhau để có tốc độ.

## 4. Log chậm và auto_explain
```sql
ALTER SYSTEM SET log_min_duration_statement = '500ms';   -- ghi mọi câu ≥ 500 ms
ALTER SYSTEM SET log_line_prefix = '%t [%p] %u@%d %a ';
SELECT pg_reload_conf();
LOAD 'auto_explain'; SET auto_explain.log_min_duration = '500ms'; SET auto_explain.log_analyze = on;
```
- `log_min_duration_statement`: biết câu nào chậm. `auto_explain`: biết **plan thật** của câu đó.
- Cũng nên bật: `log_lock_waits = on` (ghi khi chờ khóa quá `deadlock_timeout`), `log_temp_files = 0` (ghi mỗi lần sort/hash tràn ra đĩa), `log_checkpoints`, `track_io_timing`.
- Cái giá (ex07): ghi mọi câu −22% throughput, `auto_explain` với `log_analyze` ở ngưỡng 0 −35% (select-only rất nhẹ); `pg_stat_statements` gần như miễn phí.

## Đo bằng gì
`pg_stat_statements`, `pg_stat_activity`, `pg_locks`, `pg_stat_user_tables/indexes`, `pg_statio_user_tables`, `pg_stat_database`, `pg_stat_bgwriter`, `pg_stat_wal`, `pg_stat_replication` (O06), `EXPLAIN (ANALYZE, BUFFERS)`, `docker logs sql-practice-pg`, `pgbench` để đo overhead.

## Bẫy hay gặp
1. Sắp theo `mean_exec_time` rồi sửa query hiếm khi chạy.
2. Tin `mean` khi có lần chạy nguội cực lớn.
3. Quên `pg_stat_statements_reset()` trước khi đo lại sau tối ưu.
4. Bảng nhỏ quét tuần tự bị nhầm là vấn đề.
5. Bỏ sót `idle in transaction` lâu (chặn VACUUM, giữ khóa).
6. Bật `log_min_duration_statement = 0` hoặc `log_analyze` ngưỡng 0 lâu trên production.
7. `pg_cancel_backend` / `pg_terminate_backend` lên nhầm pid (luôn xem `query` và `application_name`).

## Postgres-specific
- MySQL có `performance_schema` và slow query log; Postgres gom ở `pg_stat_*` + extension. `auto_explain` không có tương đương trực tiếp.
- Từ Postgres 15, bộ đếm thống kê nằm trong shared memory (không còn file thống kê); `pg_stat_force_next_flush()` ép đẩy bộ đếm của session (dùng trong bộ chấm).
