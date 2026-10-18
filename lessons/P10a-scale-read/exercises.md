# P10a · Bài tập (Hiệu ứng quy mô: đọc)

Chạy trên DB **`lab`**. `bash tools/check.sh` tự chạy `setup.sql` (tạo `p10.t_s`, `p10.t_m`, `p10.mid`, ~5 giây). Bài đo ở quy mô 10M cần `setup-large.sql` (1–2 phút, ~1.6 GB, tạo `p10l.t_l`, không bị check xóa); xóa bằng `DROP SCHEMA p10l CASCADE;`.
**Quy tắc của module:** mỗi thí nghiệm, **ghi dự đoán ra trước** (plan, buffers, thời gian, tăng ×bao nhiêu), rồi mới đo. Pass: dự đoán đúng xu hướng ≥ 70% số ô và giải thích được mọi điểm gãy bằng số đo. Bài 1, 3, 4, 8 tự chấm (`bash tools/check.sh lessons/P10a-scale-read 01`); bài 2, 5, 6, 7 là thí nghiệm tự đối chiếu với `solutions/exNN.md`.

Dữ liệu: `p10.t_*(id PK, u, ts, grp, amount, gen, pad)`: `u` đều trong [0, 1 000 000), không tương quan với vị trí vật lý; `ts` tăng theo `id`; `gen = id / 10` (tương quan hoàn toàn với `ts`, không index). Index sẵn có: `t_*_u_idx (u)`, `t_*_ts_idx (ts)`. `p10.mid(id PK, label, pad)`: 200 000 dòng.

**Pass:** 7/8 bài, mỗi bài đo có dự đoán trước.

---

## 🟡 Điểm gãy của planner (tự chấm)

### ex01 · Plan theo selectivity
Với `p10.t_m`: loại scan planner chọn trên `t_m` (`'Seq Scan'`, `'Bitmap Heap Scan'`, `'Index Scan'`, `'Index Only Scan'`) cho `SELECT id, amount FROM p10.t_m WHERE …` với: `u < 10000` (1% bảng), `u < 200000` (20%), `u < 900000` (90%), `ts < '2025-01-01 00:00+00'::timestamptz + 300000 * interval '30 seconds'` (30%), `… + 950000 * …` (95%). Check chạy `EXPLAIN` để lấy đáp án đúng. Giải thích vì sao `u` 20% dùng index còn `ts` 95% không.
- Cột: `u_1pct, u_20pct, u_90pct, ts_30pct, ts_95pct` · **1 dòng**

### ex03 · Điểm gãy của join
`SELECT count(*) FROM p10.t_m a JOIN p10.mid b ON b.id = a.amount + 1 WHERE a.u < K`. Loại join ở đỉnh plan (`'Nested Loop'`, `'Hash Join'`, `'Merge Join'`) với K = 100, 1 000, 100 000, 900 000. Giải thích.
- Cột: `k100, k1000, k100000, k900000` · **1 dòng**

### ex04 · Sort cần bao nhiêu bộ nhớ
`SELECT count(*) FROM (SELECT id FROM p10.t_m ORDER BY amount, id) s` (tắt parallel). Tìm `work_mem` nhỏ nhất (MB nguyên) để sort **không ghi file tạm**. Trả lời bằng một `SELECT <số> AS min_work_mem_mb`. Check: ở giá trị bạn nêu không có `temp written`, ở 80% giá trị đó thì có.

---

## 📏 Thí nghiệm có dự đoán (tự đối chiếu)

### ex02 · Sweep selectivity ở ba quy mô
Dự đoán, rồi đo plan, thời gian, buffers của `SELECT count(amount) FROM T WHERE u < X` và `… WHERE ts < …` với 0.01%, 0.1%, 1%, 10%, 50% bảng ở `t_s`, `t_m`, `t_l`. Ô nào bạn đoán sai và vì sao? So với `solutions/ex02.md`.

### ex05 · Tràn bộ nhớ: sort và hash
Dự đoán, rồi đo `ORDER BY amount, id` và `GROUP BY u` (ép HashAggregate) ở ba quy mô với `work_mem` = 4MB, 64MB, 1GB: thời gian và `temp written`. Spill có làm chậm không? Vì sao (không)? So với `solutions/ex05.md`.

### ex06 · Bảng vượt shared_buffers
Dự đoán, rồi đo bằng `pg_buffercache` sau khi `pg_buffercache_evict_all()`: Seq Scan `t_m` hai lần liên tiếp (hit/read, số page của `t_m` trong cache); Seq Scan `t_l` hai lần; Bitmap 1% `t_l` hai lần. So với `solutions/ex06.md`.

### ex07 · O(n) hay O(log n)
Dự đoán thời gian ×bao nhiêu khi N tăng 100× (s → m) và 1 000× (s → l) cho: `id = 777`, `count(*)`, `max(u)` (có index), `max(amount)` (không index), top-10 theo `u`, top-10 theo `amount`. Đo và so với `solutions/ex07.md`.

---

## 🔴 Thực tế

### ex08 · "Danh sách mới nhất của nhóm cũ" (tự chấm)
Team báo: màn hình "20 bản ghi mới nhất trong lô cũ" chạy 1 ms ở staging (10k dòng) nhưng cả giây ở production. Query: `SELECT id, ts FROM p10.t_m WHERE gen < 5000 ORDER BY ts DESC LIMIT 20` (`gen < 5000` là 5% bản ghi **cũ nhất**). Plan hiện tại: Index Scan Backward trên `t_m_ts_idx` rồi lọc `gen`, bỏ 950 001 dòng, ~13 400 buffers (ở 10k dòng chỉ 137, ở 10M là 133 915). Sửa để đọc **< 3 000 buffers**, kết quả y hệt.
Bài làm: DDL, dòng `-- query`, câu SELECT (như P09). Giải thích: vì sao planner chọn plan đó, vì sao nó thường đúng và lúc nào sai, vì sao chỉ thêm index chưa đủ.
