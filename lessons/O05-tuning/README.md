# O05 · Tuning: bộ nhớ, cost của planner, checkpoint

Đọc khoảng 10 phút. Mọi số đo ở đây lấy trên Postgres 18.6 chạy trong Docker (8 CPU, 8 GB RAM cấp cho Docker) bằng `pgbench` và `EXPLAIN (ANALYZE)`. Thí nghiệm cần restart server chạy trong container tạm, không đụng `sql-practice-pg`. Ví dụ của bài 1–3 chạy trên `lab`, schema `o05` (`setup.sql`).

> Đây là tuning **tham số cấu hình**, không phải viết lại query hay thêm index (xem P02–P05). Quy trình duy nhất đáng tin: **đo → đổi một thứ → đo lại**. Các "con số khuyến nghị" chỉ là điểm bắt đầu.

## Mục tiêu: sau buổi này bạn làm được
- Nói được mỗi tham số bộ nhớ làm gì, **tính theo cái gì** (server, kết nối, hay từng node của plan).
- Đọc công thức cost của planner và biết `random_page_cost`, `effective_cache_size` tác động chỗ nào.
- Chẩn đoán checkpoint quá dày bằng `pg_stat_checkpointer`.
- Phân biệt tham số đổi được bằng reload, cần restart, và tham số **đổi cam kết độ bền**.

---

## 1. Bộ nhớ: ba tham số, ba "đơn vị tính" khác nhau
| Tham số | Mặc định | Tính theo | Làm gì |
|---|---|---|---|
| `shared_buffers` | 128MB | **cả server** (một lần) | cache trang của Postgres, dùng chung mọi kết nối; đổi cần **restart** |
| `work_mem` | 4MB | **mỗi node** sort/hash, mỗi kết nối (và mỗi parallel worker) | bộ nhớ cho một thao tác sort/hash; hết thì tràn ra đĩa |
| `maintenance_work_mem` | 64MB | mỗi thao tác bảo trì | `CREATE INDEX`, `VACUUM`; ở lab đặt 256MB |
| `effective_cache_size` | 4GB | không cấp phát gì | chỉ là **gợi ý cho planner**: "OS + shared_buffers có thể giữ bao nhiêu dữ liệu" |

Hai điều hay nhầm:
- **`work_mem` không phải trần của truy vấn.** Mỗi node sort/hash xin riêng. Một truy vấn có 3 `Sort` (3 thứ tự khác nhau) với `work_mem = 256MB` đã dùng **94,9 + 90,2 + 85,5 = 270,6 MB** (ex06). Nhân tiếp với số kết nối và số parallel worker. Hash còn được nhân với `hash_mem_multiplier` (mặc định 2).
- **Dung lượng đĩa ≠ bộ nhớ cần.** Sort 600 000 dòng `(id, payload)` tràn ra đĩa chỉ 46 MB ở `work_mem = 4MB`, nhưng để sort **trong RAM** cần ≈ **73 MB**: ở 64MB vẫn tràn, ở 96MB mới xong (ex03).

`shared_buffers` cũng không phải "càng to càng nhanh": Linux còn có page cache, một trang có thể nằm ở cả hai chỗ. Trên máy thí nghiệm (dữ liệu 905 MB), tăng `shared_buffers` từ 128MB lên 2GB đẩy tỉ lệ cache hit từ ≈ 64% lên ≈ 99% mà throughput select-only **gần như không đổi** (21–23k tps, trong dải nhiễu), vì page cache của OS đỡ phần đọc (ex08).

## 2. Cost của planner: `random_page_cost`, `seq_page_cost`, `cpu_*`
Planner không đo thời gian; nó cộng **điểm cost** từ các hằng số:

| Hằng số | Mặc định | Ý nghĩa |
|---|---|---|
| `seq_page_cost` | 1.0 | đọc một trang tuần tự |
| `random_page_cost` | 4.0 | đọc một trang ngẫu nhiên |
| `cpu_tuple_cost` | 0.01 | xử lý một dòng |
| `cpu_index_tuple_cost` | 0.005 | xử lý một mục index |
| `cpu_operator_cost` | 0.0025 | một phép toán/hàm |

Seq Scan không lọc: **cost = `relpages × seq_page_cost + reltuples × cpu_tuple_cost`** (ex02 kiểm chứng đúng với `EXPLAIN`).

Lời khuyên "đặt `random_page_cost = 1.1` cho SSD" đúng *khi dữ liệu thật sự phải đọc ngẫu nhiên từ đĩa nhanh*. Đã đo trên bảng 1 triệu dòng, 74 MB, **đã nằm trong cache**, khóa không tương quan với thứ tự vật lý:

| Độ chọn lọc | Plan khi `rpc=4` | Plan khi `rpc=1.1` | Seq ms | Bitmap ms | Index ms |
|---|---|---|---|---|---|
| 0,1% | Bitmap | Bitmap | 49,8 | 1,1 | 0,64 |
| 1% | Bitmap | Bitmap | 38,3 | 10,7 | 6,5 |
| 5% | Bitmap | Bitmap | 59,0 | 29,3 | 55,5 |
| 20% | Bitmap | **Index Scan** | 84,0 | 57,1 | **187,8** |
| 50% | Seq Scan | **Index Scan** | 113,9 | 103,4 | **425,5** |
| 80% | Seq Scan | Seq Scan | 82,3 | 172,2 | 693,6 |

Ở 20–50%, `rpc=1.1` làm planner chọn Index Scan chậm hơn đường tối ưu **3–4 lần**. Tham số này phải khớp với phần cứng *và* với tỉ lệ dữ liệu nằm trong cache; đổi nó là đổi plan của **mọi** truy vấn, nên phải đo lại trên workload thật (ex04).

## 3. WAL và checkpoint
Checkpoint ghi mọi trang bẩn xuống đĩa. Có hai lý do để checkpoint chạy: hết `checkpoint_timeout` (mặc định 5 phút, "timed") hoặc WAL đầy tới `max_wal_size` (mặc định 1GB, "requested"). Checkpoint **do WAL đầy gây ra** là dấu hiệu `max_wal_size` quá nhỏ: chúng dồn dập, kéo theo ghi nhiều và `full_page_writes` sau mỗi checkpoint.
```sql
SELECT num_timed, num_requested, round(write_time) AS write_ms, buffers_written FROM pg_stat_checkpointer;   -- PG17+; trước đó là pg_stat_bgwriter
```
Đã đo (pgbench TPC-B, scale 20, 8 client, 60 s): `max_wal_size = 64MB` → **21 checkpoint requested**, 79 274 buffer ghi, **1 040 tps**; `max_wal_size = 4GB` → **0 checkpoint** trong lúc chạy, **1 277 tps** (+23%). Lưu ý: 60 s ngắn hơn `checkpoint_timeout`, nên phía 4GB chưa phải trả checkpoint nào; chênh lệch dài hạn nhỏ hơn (ex05). Cái giá của `max_wal_size` lớn: **phục hồi sau crash lâu hơn** và tốn đĩa cho WAL.

## 4. Thứ làm nhanh nhất lại là thứ đổi cam kết
Đo trên TPC-B scale 60, 16 client, 45 s:

| Cấu hình (cộng dồn) | tps | so với mặc định |
|---|---|---|
| mặc định (`shared_buffers=128MB`, `max_wal_size=1GB`) | 2 346 | – |
| + `max_wal_size=8GB` | 2 541 | +8% |
| + `shared_buffers=2GB` | 2 524 | +8% (không thêm) |
| + `synchronous_commit=off` | **5 721** | **+144%** |

`synchronous_commit = off` không chờ WAL xuống đĩa mới báo `COMMIT`: khi crash có thể mất vài trăm mili-giây giao dịch **đã báo thành công** (dữ liệu vẫn nhất quán, không hỏng). Có thể hợp lý cho dữ liệu chấp nhận mất (log, session), **không** cho tiền bạc; và có thể đặt theo từng transaction (`SET LOCAL`). `fsync = off` thì khác hẳn: có thể làm hỏng cả cụm sau crash; không dùng trên dữ liệu thật (ex07).

## 5. Quy trình và phạm vi áp dụng
- Xem tham số đổi bằng cách nào: `SELECT name, setting, unit, context FROM pg_settings WHERE name = …` — `context`: `postmaster` (restart), `sighup` (reload), `user` (`SET` được).
- Đặt tạm: `SET LOCAL work_mem = '100MB'` trong một transaction (an toàn nhất cho truy vấn báo cáo). Đặt cho một nhóm: `ALTER ROLE report SET work_mem = '128MB'`. Đặt toàn server: `ALTER SYSTEM SET …; SELECT pg_reload_conf();` hoặc sửa `postgresql.conf`.
- Đổi **một** thứ mỗi lần, đo bằng cùng một workload, chạy đủ lâu để vượt `checkpoint_timeout`, lặp lại để biết nhiễu.

## Đo bằng gì
`pg_settings`, `EXPLAIN (ANALYZE, BUFFERS)` (`Sort Method: … Disk/Memory`, `temp read/written`), `pg_stat_checkpointer`, `pg_stat_database` (`blks_hit`, `blks_read`, `temp_files`, `temp_bytes`), `log_checkpoints`, `log_temp_files`, `pgbench`.

## Bẫy hay gặp
1. Đặt `work_mem` toàn cục theo "một truy vấn" mà quên nhân với node × kết nối × worker (nguy cơ hết RAM).
2. Chép "bộ cấu hình tối ưu" từ blog mà không đo.
3. Chỉnh `random_page_cost` mà không kiểm tra dữ liệu có nằm trong cache hay không.
4. Tin rằng `shared_buffers` to là nhanh hơn; không tính tới page cache.
5. Bỏ qua checkpoint "requested" dồn dập trong log.
6. Đo trong 60 giây rồi kết luận về checkpoint.
7. Tắt `fsync`/`synchronous_commit` để "nhanh hơn" mà không hiểu mình mất gì.
8. Đo tuning bằng một lần chạy duy nhất: nhiễu ±10% là bình thường.

## Postgres-specific
- MySQL InnoDB thường đặt buffer pool rất lớn (hay gặp 50–75% RAM) và có thể bỏ qua cache OS; Postgres chủ động dựa vào cả `shared_buffers` lẫn page cache nên quy tắc khác.
- Từ PG17 có `pg_stat_checkpointer` (trước đó số checkpoint nằm trong `pg_stat_bgwriter`).
- `work_mem` tính theo node, `hash_mem_multiplier` (mặc định 2 từ PG15) cho phép hash dùng nhiều hơn sort.
