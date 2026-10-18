# O05 · Bài tập (Tuning)

Bài 1–3 chạy trên DB **`lab`**, schema `o05` (script chấm tự chạy `setup.sql`: bảng `o05.items` 200 000 dòng, `o05.big` 600 000 dòng). Tự chấm: `bash tools/check.sh lessons/O05-tuning 01` (đặt bài làm ở `answers/exNN.sql`).
Bài 4–8 là thí nghiệm thật (`mode: manual`), đối chiếu với `solutions/exNN.md` (số đo thật, Postgres 18.6, 8 CPU). Thí nghiệm cần restart hoặc đổi cấu hình server (bài 5, 7, 8) chạy trong **container tạm**, không đổi `sql-practice-pg`:
```bash
docker run -d --name o05-pg --shm-size=1g -e POSTGRES_PASSWORD=postgres postgres:18
docker exec o05-pg pgbench -i -s 60 -q -U postgres postgres     # ≈ 905 MB
# đổi tham số cần restart:  ALTER SYSTEM SET shared_buffers='1GB';  rồi  docker restart o05-pg
# dọn: docker rm -f o05-pg
```
Mỗi lần đo nên chạy đủ lâu và **lặp lại**: nhiễu ±10% là bình thường.

**Pass:** 7/8 (3 bài chấm tự động + 5 bài tự đối chiếu).

---

## 🟢 Cơ bản

### ex01 · Bộ nhớ đang cấu hình (MB)
Liệt kê bốn tham số `shared_buffers`, `work_mem`, `maintenance_work_mem`, `effective_cache_size` với giá trị hiện tại **quy ra MB** (1 chữ số lẻ). Chú ý: `pg_settings.setting` không cùng đơn vị cho mọi tham số.
- Cột: `name`, `mb` · Sắp xếp: `name`
- Kỳ vọng: **4 dòng**; dòng đầu là `effective_cache_size`.

### ex02 · Seq Scan "đáng giá" bao nhiêu điểm
Với bảng `o05.items`, tính cost mà planner gán cho `SELECT * FROM o05.items` chỉ từ số liệu thống kê và các hằng số cost, **không gọi EXPLAIN**: `relpages × seq_page_cost + reltuples × cpu_tuple_cost`. Trả `relpages`, `reltuples` (số nguyên) và `seq_scan_cost` (2 chữ số lẻ). Bộ chấm so với cost thật trong plan.
- Cột: `relpages`, `reltuples`, `seq_scan_cost` · Một dòng

---

## 🟡 Kết hợp

### ex03 · work_mem vừa đủ
Truy vấn `SELECT id, payload FROM o05.big ORDER BY payload` đang tràn ra đĩa với `work_mem = 4MB`. Viết lệnh `SET LOCAL work_mem = '…'` (một câu, dùng trong transaction) sao cho sort chạy **hoàn toàn trong RAM** (không ghi file tạm), nhưng **không vượt 256MB** (vì mỗi node × mỗi kết nối đều có thể xin chừng đó). Đoán trước, rồi dùng `EXPLAIN (ANALYZE)` để tìm con số nhỏ nhất đủ.
- Bài làm là một câu `SET LOCAL`. Bộ chấm chạy truy vấn trên và kiểm `temp_written = 0` và `work_mem ≤ 256MB`.

### ex04 · random_page_cost không phải thuốc tiên (manual)
Tạo bảng 1 triệu dòng với cột `k` ngẫu nhiên (không tương quan với thứ tự vật lý) và index trên `k`. Với truy vấn `WHERE k BETWEEN 1 AND X` ở các độ chọn lọc 0,1% đến 80%, ghi lại: plan planner chọn khi `random_page_cost = 4` và khi `1,1`; thời gian thật của Seq / Bitmap / Index scan (ép từng loại bằng `enable_*` trong một transaction, lấy tốt nhất của 3 lần). `random_page_cost = 1,1` có luôn tốt hơn cho SSD không? Chỗ nào planner chọn sai?

### ex05 · Checkpoint dồn dập (manual)
Trong container tạm, chạy `pgbench -c8 -j4 -T60` với `max_wal_size = 64MB`, rồi `4GB` (đổi bằng `ALTER SYSTEM` + `pg_reload_conf()`; reset `pg_stat_reset_shared('checkpointer')` trước mỗi lần). Đọc `pg_stat_checkpointer`. Kết luận gì về `num_requested`? Phép đo 60 giây này công bằng cho phía 4GB không, và cái giá của `max_wal_size` lớn là gì?

---

## 🔴 Thực tế

### ex06 · "Nâng work_mem lên 1GB cho nhanh" (manual)
Đồng nghiệp đề xuất `ALTER SYSTEM SET work_mem = '1GB'` vì báo cáo cuối tháng đang tràn ra đĩa. Server 16 GB RAM, `max_connections = 200`. Tính trường hợp xấu nhất. Rồi đo bộ nhớ thật mà **một** truy vấn dùng khi có 3 node `Sort` (ví dụ 3 window function với 3 `ORDER BY` khác nhau) và so thời gian giữa `work_mem` lớn với `4MB`. Đề xuất cách làm đúng cho báo cáo đó.

### ex07 · "Server mới mà chạy chậm" (manual)
Team vừa chuyển lên máy mới và báo `pgbench` chỉ đạt vài nghìn tps với cấu hình mặc định. Trong container tạm, đo TPC-B (`-c16 -j4 -T45`, scale 60) lần lượt: mặc định → `max_wal_size=8GB` → `shared_buffers=2GB` → `synchronous_commit=off`. Mỗi bước đổi được bao nhiêu? Cái nào đáng làm, cái nào phải hỏi lại về **yêu cầu độ bền** trước? Khác gì giữa `synchronous_commit=off` và `fsync=off`?

---

## 📏 ex08 · Câu hỏi quy mô: shared_buffers bao nhiêu là đủ?
Dữ liệu 905 MB (`pgbench -s 60`), select-only `-S -c8`. **Dự đoán** (viết ra trước) tỉ lệ cache hit và tps ở `shared_buffers` = 128MB, 256MB, 512MB, 1GB, 2GB. Rồi đo (restart mỗi mức, làm nóng 10 s, đo 20 s). Tăng `shared_buffers` có tăng tps tương ứng với tỉ lệ cache hit không? Vì sao? Giới hạn bộ nhớ container (`--memory`) thay đổi điều gì?
Lời giải và số đo thật: `solutions/ex08.md`.
