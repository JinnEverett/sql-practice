# O03 · Bài tập (Monitoring)

Bài 1–3 chạy trên DB **`lab`**, schema `o03` (script chấm tự chạy `setup.sql`, rồi chạy một **tải giả lập** (`workload.sql`: 3 lần `pg_sleep(0.5)`, một lần `pg_sleep(0.8)`, 500 lần tra bảng nhỏ, 2 lần quét bảng lớn `o03.big`), rồi chấm câu trả lời của bạn trên số liệu thống kê vừa sinh ra). Bài 4–7 là bài quan sát thật (`mode: manual`), đối chiếu với `solutions/exNN.md` (số đo thật).
Mỗi bài 1–3 là **một câu `SELECT`** vào `answers/exNN.sql`. Tự chấm: `bash tools/check.sh lessons/O03-monitoring 01`. Để tự xem số liệu: chạy `setup.sql`, rồi `docker exec -i sql-practice-pg psql -U postgres -d lab -q < lessons/O03-monitoring/workload.sql`.

**Pass:** 6/7 (3 bài chấm tự động + 4 bài tự đối chiếu).

---

## 🟢 Cơ bản

### ex01 · Top 5 theo tổng thời gian
Từ `pg_stat_statements`, lấy 5 câu lệnh chiếm **tổng thời gian thực thi** lớn nhất, bỏ các truy vấn vào chính `pg_stat_statements`.
- Cột: `query` (cắt 80 ký tự), `calls`, `total_ms` (1 chữ số lẻ), `mean_ms` (2 chữ số lẻ) · Sắp xếp: `total_ms` giảm dần
- Kỳ vọng: 5 dòng; dòng đầu là `SELECT pg_sleep($1) AS a` (3 lần, ≈ 1500 ms).

### ex02 · Query ngốn I/O nhất
3 câu lệnh chạm nhiều **block** nhất (`shared_blks_hit + shared_blks_read`), kèm số block trung bình mỗi lần gọi. Bỏ truy vấn vào chính `pg_stat_statements`.
- Cột: `query` (cắt 80), `calls`, `blks_total`, `blks_per_call` (1 chữ số lẻ) · Sắp xếp: `blks_total` giảm dần
- Kỳ vọng: 3 dòng; dòng đầu là `SELECT count(*) FROM o03.big WHERE grp = $1`; truy vấn `o03.small` gọi 500 lần nhưng chỉ vài block mỗi lần.

### ex03 · Bảng lớn bị quét tuần tự
Trong schema `o03`, liệt kê bảng **lớn hơn 10 MB** mà số lần quét tuần tự **nhiều hơn** số lần quét index (idx_scan NULL tính là 0).
- Cột: `relname, seq_scan, idx_scan, seq_tup_read, size` (`pg_size_pretty`) · Sắp xếp: `seq_tup_read` giảm dần
- Kỳ vọng: 1 dòng (`big`).

---

## 🟡 Kết hợp

### ex04 · Ai đang chặn ai? (manual)
Mở hai session: A `BEGIN; UPDATE o03.small SET v = v + 1 WHERE id = 1;` rồi giữ nguyên; B `UPDATE o03.small SET v = 0 WHERE id = 1;` (sẽ treo). Từ session thứ ba, viết truy vấn cho ra bảng **(pid bị chặn, pid chặn, câu lệnh bị chặn, trạng thái kẻ chặn, tuổi transaction kẻ chặn)**. Rồi tạo tình huống "idle in transaction" và xử lý.

### ex05 · Log query chậm và auto_explain (manual)
Trong một session, ghi log mọi câu ≥ 200 ms và bật `auto_explain` (ngưỡng 0, có `log_analyze`). Chạy `pg_sleep(0.05)`, `pg_sleep(0.3)` và một truy vấn quét `o03.big`. Đọc log (`docker logs sql-practice-pg`). Câu nào được ghi, câu nào không, vì sao? `auto_explain` cho biết điều gì mà `pg_stat_statements` không cho?

---

## 🔴 Thực tế

### ex06 · "Database chậm cả tuần" (manual)
Team báo: *"Cả tuần nay hệ thống ì ạch, không ai biết query nào."* Chạy `shop-workload.sql` trên `shop_m`, tìm **top 5 query tệ nhất** theo `pg_stat_statements`, chẩn đoán từng câu bằng `EXPLAIN (ANALYZE, BUFFERS)` và đề xuất cách xử lý, xếp theo mức lợi/công sửa. Có câu nào mà `mean_exec_time` đánh lừa bạn không?

---

## 📏 ex07 · Câu hỏi quy mô: giám sát tốn bao nhiêu?
Dùng `pgbench -S -c4 -j2 -T8` trên DB có 1M dòng. **Dự đoán** throughput (tps) khi: `pg_stat_statements.track = none`, `log_min_duration_statement = 0`, `auto_explain` với `log_analyze` ngưỡng 0, so với mặc định. Rồi đo (đổi cấu hình bằng `ALTER SYSTEM` + `pg_reload_conf()`, nhớ reset sau khi đo). Với truy vấn nặng hơn 100 lần thì phần trăm overhead đổi thế nào?
Lời giải và số đo thật: `solutions/ex07.md`.
