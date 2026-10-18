# P03 · Bài tập (EXPLAIN)

Mọi bài trừ ex09 chạy trên DB **`lab`** schema `p03` (script chấm tự chạy `setup.sql`, ~3 giây). Dựng sẵn:
`p03.o` (400 000 đơn: `id, user_id, status, created_at, amount`; index `o_user_idx(user_id)`, `o_created_idx(created_at)`), `p03.u` (20 000 khách: `id, region, name`).
Các plan trong đề **đã đo thật**; chạy lại `EXPLAIN (ANALYZE, BUFFERS)` để đối chiếu: `rows`, `loops`, `Batches`, kích thước sort giống nhau, còn thời gian và hit/read thì khác máy.
Bài 1–6 là **đọc plan**: bài làm là một câu `SELECT` trả về 1 dòng với các cột cho sẵn. Hãy **tự chạy query để kiểm chứng** các con số khớp với dữ liệu thật thay vì gõ tay. Tự chấm: `bash tools/check.sh lessons/P03-explain 01`.

**Pass:** "Đọc đúng 5 plan": đúng 5/6 bài đọc plan và 7/9 bài tổng.

---

## 🟢 Cơ bản

### ex01 · Seq Scan song song
```
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF) SELECT count(*) FROM p03.o WHERE status = 'delivered';

 Finalize Aggregate  (cost=6788.90..6788.91 rows=1 width=8) (actual rows=1.00 loops=1)
   Buffers: shared hit=3334
   ->  Gather  (cost=6788.68..6788.89 rows=2 width=8) (actual rows=3.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=3334
         ->  Partial Aggregate  (cost=5788.68..5788.69 rows=1 width=8) (actual rows=1.00 loops=3)
               Buffers: shared hit=3334
               ->  Parallel Seq Scan on o  (cost=0.00..5417.33 rows=148539 width=0) (actual rows=118666.67 loops=3)
                     Filter: (status = 'delivered'::text)
                     Rows Removed by Filter: 14667
                     Buffers: shared hit=3334
```
Trả về số worker thực tế chạy, **tổng** số dòng thỏa filter, **tổng** số dòng bị loại, và số page bảng `o` được đọc.
- Cột: `workers_launched, matched_rows, removed_rows, buffers`
- Kỳ vọng: **1 dòng**: `2 | 356000 | 44000 | 3334`

### ex02 · Index Scan hay Bitmap?
```
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF) SELECT id, amount FROM p03.o WHERE user_id = 777;
 Bitmap Heap Scan on o  (cost=4.58..80.18 rows=20 width=8) (actual rows=20.00 loops=1)
   Recheck Cond: (user_id = 777)
   Heap Blocks: exact=20
   ->  Bitmap Index Scan on o_user_idx  (cost=0.00..4.57 rows=20 width=0) (actual rows=20.00 loops=1)

EXPLAIN (ANALYZE, BUFFERS, TIMING OFF) SELECT id, amount FROM p03.o WHERE created_at < '2025-01-02';
 Index Scan using o_created_idx on o  (cost=0.42..44.32 rows=1080 width=8) (actual rows=1093.00 loops=1)
   Index Cond: (created_at < '2025-01-02 00:00:00+00'::timestamp with time zone)
   Buffers: shared hit=13 read=2
```
Hai query đều dùng index nhưng khác node. Trả về mỗi cột (`user_id`, `created_at`): giá trị tuyệt đối của `correlation` trong `pg_stats` (làm tròn 1 chữ số) và node scan tương ứng (`'Bitmap Heap Scan'` hay `'Index Scan'`).
- Cột: `attname, abs_corr, node` · Sắp xếp: `attname`
- Kỳ vọng: **2 dòng**: `created_at | 1.0 | Index Scan` và `user_id | 0.0 | Bitmap Heap Scan`

---

## 🟡 Kết hợp

### ex03 · Nested Loop và `loops`
```
EXPLAIN (ANALYZE, BUFFERS) SELECT u.name, o.amount FROM p03.u u JOIN p03.o o ON o.user_id = u.id WHERE u.id <= 5;

 Nested Loop  (cost=4.87..410.28 rows=100 width=14) (actual time=0.019..0.128 rows=100.00 loops=1)
   Buffers: shared hit=118
   ->  Index Scan using u_pkey on u  (cost=0.29..8.38 rows=5 width=14) (actual time=0.002..0.004 rows=5.00 loops=1)
         Index Cond: (id <= 5)
         Buffers: shared hit=3
   ->  Bitmap Heap Scan on o  (cost=4.58..80.18 rows=20 width=8) (actual time=0.007..0.021 rows=20.00 loops=5)
         Recheck Cond: (u.id = user_id)
         Heap Blocks: exact=100
         Buffers: shared hit=115
         ->  Bitmap Index Scan on o_user_idx  (cost=0.00..4.57 rows=20 width=0) (actual time=0.003..0.003 rows=20.00 loops=5)
               Index Cond: (user_id = u.id)
               Buffers: shared hit=15
```
Trả về: số dòng phía ngoài, số lần (loops) phía trong chạy, số dòng mỗi lần chạy phía trong, tổng dòng trả ra của join, và tổng số page heap phía trong đã đọc. Tính `outer_rows` và `rows_returned` bằng query trên dữ liệu thật.
- Cột: `outer_rows, loops, rows_per_loop, rows_returned, heap_blocks`
- Kỳ vọng: **1 dòng**: `5 | 5 | 20 | 100 | 100`

### ex04 · Hash Join và batch
```
-- (a) work_mem mặc định (4MB), có parallel
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF) SELECT u.region, count(*), sum(o.amount) FROM p03.o o JOIN p03.u u ON u.id = o.user_id GROUP BY u.region;
   …
   ->  Hash Join  (cost=578.00..6016.26 rows=166127 width=11) (actual rows=133333.33 loops=3)
         Hash Cond: (o.user_id = u.id)
         ->  Parallel Seq Scan on o  (cost=0.00..5000.67 rows=166667 width=8) (actual rows=133333.33 loops=3)
         ->  Hash  (cost=328.00..328.00 rows=20000 width=11) (actual rows=20000.00 loops=3)
               Buckets: 32768  Batches: 1  Memory Usage: 1131kB
               ->  Seq Scan on u  (cost=0.00..328.00 rows=20000 width=11) (actual rows=20000.00 loops=3)

-- (b) SET work_mem = '64kB'
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF) SELECT count(*) FROM p03.o o JOIN p03.u u ON u.id = o.user_id;
 Aggregate  (…) (actual rows=1.00 loops=1)
   Buffers: shared hit=3462, temp read=1081 written=1081
   ->  Hash Join  (cost=657.00..12246.22 rows=398704 width=0) (actual rows=400000.00 loops=1)
         Hash Cond: (o.user_id = u.id)
         Buffers: shared hit=3462, temp read=1081 written=1081
         ->  Seq Scan on o  (cost=0.00..7334.00 rows=400000 width=4) (actual rows=400000.00 loops=1)
         ->  Hash  (cost=328.00..328.00 rows=20000 width=4) (actual rows=20000.00 loops=1)
               Buckets: 8192  Batches: 8  Memory Usage: 154kB
               Buffers: shared hit=128, temp written=49
               ->  Seq Scan on u  (cost=0.00..328.00 rows=20000 width=4) (actual rows=20000.00 loops=1)
```
Trả về: tên bảng được băm (build side, một chữ cái trong plan), số dòng của nó (đếm bằng query), số `Batches` của (a) và (b), và số temp page đã ghi ở (b). Rồi tự trả lời trong đầu: vì sao temp page ghi ra (1 081) nhiều hơn hẳn kích thước bảng `u` (128 page)?
- Cột: `build_table, build_rows, batches_a, batches_b, temp_written_b`
- Kỳ vọng: **1 dòng**: `u | 20000 | 1 | 8 | 1081`

### ex05 · Sort tràn đĩa
```
SET max_parallel_workers_per_gather = 0;
-- (a) work_mem = 4MB (mặc định của DB này)
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF) SELECT id, amount FROM p03.o ORDER BY amount, id;
 Sort  (cost=50023.78..51023.78 rows=400000 width=8) (actual rows=400000.00 loops=1)
   Sort Key: amount, id
   Sort Method: external merge  Disk: 7072kB
   Buffers: shared hit=3337, temp read=884 written=888
-- (b) SET work_mem = '64MB'
 Sort  (cost=44553.28..45553.28 rows=400000 width=8) (actual rows=400000.00 loops=1)
   Sort Method: quicksort  Memory: 21664kB
   Buffers: shared hit=3334
```
Trả về: kích thước sort trên đĩa (kB) ở (a), bộ nhớ dùng ở (b) (kB), tỉ lệ bộ nhớ/đĩa (1 chữ số thập phân), số temp page đã ghi ở (a), và **`work_mem` nhỏ nhất theo MB nguyên** để query này sort hoàn toàn trong RAM. Giá trị cuối phải tự tìm bằng thực nghiệm (`SET work_mem = '…MB'` rồi `EXPLAIN ANALYZE`).
- Cột: `disk_kb, mem_kb, mem_to_disk, temp_written_a, min_work_mem_mb`
- Kỳ vọng: **1 dòng**: `7072 | 21664 | 3.1 | 888 | 19`

---

## 🔴 Thực tế

### ex06 · "Cost thấp mà chạy chậm"
Team báo: query lọc đơn pending có số tiền 0 chạy lâu hơn dự kiến và plan sau đó chọn sai khi join thêm bảng khác.
```
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF) SELECT id FROM p03.o WHERE status = 'pending' AND amount = 0;
 Seq Scan on o  (cost=0.00..9334.00 rows=4 width=4) (actual rows=400.00 loops=1)
   Filter: ((status = 'pending'::text) AND (amount = 0))
   Rows Removed by Filter: 399600
   Buffers: shared hit=3334
```
Trả về: số dòng ước lượng và thực tế, hệ số lệch (nguyên, thực tế / ước lượng), và con số ước lượng độc lập mà planner đã tính: `N × P(status='pending') × P(amount=0)` (làm tròn nguyên), tính từ dữ liệu thật. Cột cuối giải thích vì sao ước lượng là 4.
- Cột: `est_rows, actual_rows, error_factor, est_independent`
- Kỳ vọng: **1 dòng**: `4 | 400 | 100 | 4`

---

## 🧪 Thực hành plan

### ex07 · Điểm gãy của planner
Với `p03.o`, chạy `EXPLAIN` (không ANALYZE) cho từng query và xác định node scan mà planner chọn trên `o`: `'Seq Scan'`, `'Bitmap Heap Scan'`, `'Index Scan'` hay `'Index Only Scan'`.
(1) `WHERE user_id < 60`; (2) `WHERE user_id < 5000` (25% dòng); (3) `WHERE user_id < 20000` (tất cả); (4) `WHERE created_at < '2025-03-15'` (≈ 20% dòng); (5) `WHERE created_at < '2025-11-26'` (≈ 90% dòng). Mọi query: `SELECT id, amount FROM p03.o WHERE …`.
Trả lời bằng một `SELECT` 1 dòng gồm 5 cột. Check chạy `EXPLAIN` thật để lấy đáp án, không dùng số cố định. Giải thích: vì sao (2) ở 25% dòng vẫn dùng index còn (4) với 20% lại là loại index khác?
- Cột: `q1, q2, q3, q4, q5` · Kỳ vọng: **1 dòng**

### ex08 · EXPLAIN ANALYZE mà không đổi dữ liệu
`p03.acct` có 1 000 tài khoản, `balance = 100`, và trigger đếm số lần UPDATE thật sự chạy. Đo plan thực tế (có `ANALYZE`) của `UPDATE p03.acct SET balance = balance + 1 WHERE id <= 100` sao cho **dữ liệu bảng không đổi** sau khi chạy. Check kiểm: tổng `balance` vẫn 100 000, và trigger đã chạy đúng 100 lần (chứng tỏ UPDATE thực sự chạy).

---

## 📏 Câu hỏi quy mô

### ex09 · Plan đổi hình theo quy mô
Query: `SELECT u.country, count(*) AS n, sum(o.total_amount) AS revenue FROM orders o JOIN users u ON u.id = o.user_id WHERE o.status = 'delivered' GROUP BY u.country ORDER BY revenue DESC`.
**Dự đoán trước** (ghi ra): ở `shop_xs`, `shop_s`, `shop_m` và `shop_l` (10M) plan có khác nhau không (loại join, có parallel không), cost và thời gian tăng bao nhiêu lần khi N tăng 100×. Sau đó chạy `EXPLAIN` và `bench/bench.sh <query> --scales xs,s,m` (thêm `l` nếu đã sinh). Đối chiếu `solutions/ex09.md`.
