# P03 · EXPLAIN (ANALYZE, BUFFERS): đọc plan

Đọc khoảng 10 phút. Mọi plan trong bài chạy trên `lab.p03` (`setup.sql`: `o` 400 000 đơn, `u` 20 000 khách, index `o_user_idx`, `o_created_idx`), Postgres 18.6. Số **rows, loops, buffers** tái hiện được trên máy bạn; **thời gian và hit/read** thì không. Giới hạn của phép đo: cache trong plan đều "ấm" (`shared hit`), nên chưa phản ánh đọc từ đĩa lạnh.

## Mục tiêu: sau buổi này bạn làm được
- Đọc một plan từ node lá lên gốc và nói được: node làm gì, được gọi bao nhiêu lần (`loops`), cho ra bao nhiêu dòng, đọc bao nhiêu page.
- Phân biệt **ước lượng** (`cost`, `rows` trong ngoặc đầu) với **thực tế** (`actual`), và phát hiện chỗ ước lượng lệch.
- Nhận diện Seq Scan / Index Scan / Bitmap Heap Scan; Nested Loop / Hash Join / Merge Join; Sort tràn ra đĩa; Hash nhiều batch.
- Chạy `EXPLAIN ANALYZE` lên câu lệnh ghi dữ liệu mà không làm hỏng dữ liệu.

---

## 1. Ba mức EXPLAIN
| lệnh | chạy query? | cho biết |
|---|---|---|
| `EXPLAIN q` | không | plan + **cost và rows ước lượng** |
| `EXPLAIN ANALYZE q` | **có** | thêm `actual time`, `rows`, `loops` |
| `EXPLAIN (ANALYZE, BUFFERS) q` | có | thêm số page `shared hit/read`, `temp read/written` |

**`ANALYZE` thực sự chạy câu lệnh.** `EXPLAIN ANALYZE UPDATE …` sửa dữ liệu thật và bắn trigger (ex08). Bọc trong `BEGIN; … ROLLBACK;`.

Phần thực tế dùng `(ANALYZE, BUFFERS)` và (khi cần so sánh) `TIMING OFF` để bớt nhiễu. Từ Postgres 18, `BUFFERS` bật sẵn khi có `ANALYZE`, và mỗi node scan index có thêm dòng `Index Searches: N`.

## 2. Đọc một dòng của node
```
Parallel Seq Scan on o  (cost=0.00..5417.33 rows=148539 width=0) (actual rows=118666.67 loops=3)
  Filter: (status = 'delivered'::text)
  Rows Removed by Filter: 14667
  Buffers: shared hit=3334
```
- `cost=a..b`: a = chi phí trước khi ra dòng đầu (startup), b = tổng. Đơn vị tùy ý (≈ một lần đọc page tuần tự = 1.0). **Không so với giây**.
- `rows` trong ngoặc đầu là **ước lượng**; `actual rows` là thực tế **trên mỗi lần chạy (loop)**.
- `loops=3`: node chạy 3 lần (ở đây 3 process: 1 leader + 2 worker). **Tổng dòng thực = actual rows × loops** = 118 666.67 × 3 = 356 000 (bằng số đơn `delivered`). Quên nhân `loops` là lỗi đọc plan phổ biến nhất.
- `Rows Removed by Filter` cũng tính trên mỗi loop. Cũng ×3 = 44 000.
- `Buffers: shared hit=3334` ở node con tính tổng của mọi loop/worker: 3 334 = đúng số page của bảng `o` (một lượt Seq Scan trọn bảng).
- Node cha **gồm** thời gian và buffers của con. Muốn biết node nào tốn nhất, trừ chi phí của con.

## 3. Cách quét bảng
| node | khi nào planner chọn |
|---|---|
| **Seq Scan** | đọc tuần tự toàn bộ page; rẻ khi lấy tỉ lệ lớn của bảng hoặc bảng nhỏ |
| **Index Scan** | đi theo index, mỗi dòng nhảy sang heap; hợp khi ít dòng, **hoặc** thứ tự index khớp thứ tự vật lý (correlation cao) |
| **Bitmap Heap Scan** | gom hết vị trí dòng từ index vào bitmap, sắp theo page, rồi đọc heap **một lần mỗi page**; hợp khi lấy một lượng dòng vừa phải và rải rác |
| **Index Only Scan** | không đụng heap (P02) |

Đo trên `lab.p03.o` (3 334 page):

| query | dòng | node | heap page đọc |
|---|---|---|---|
| `user_id = 777` | 20 | Bitmap Heap Scan | 20 (mỗi dòng một page) |
| `user_id < 60` | 1 180 | Bitmap Heap Scan | 1 180 |
| `user_id < 2000` | 39 980 | Bitmap Heap Scan | **3 334** (cả bảng) |
| `created_at < '2025-01-02'` | 1 093 | **Index Scan** | 13 (index) |

`created_at` tăng theo thứ tự chèn nên `correlation` = 1.0: các dòng liền nhau trên index cũng liền nhau trong heap, Index Scan đọc heap tuần tự. `user_id` có correlation ≈ 0 (rải đều) nên mỗi dòng thường nằm ở một page khác, Bitmap hợp hơn. Chọn node dựa trên **selectivity và correlation** (P04 về thống kê, P10a về điểm gãy).

## 4. Ba kiểu join
| node | cách chạy | hợp khi |
|---|---|---|
| **Nested Loop** | với mỗi dòng bên ngoài, tra bên trong (`loops` = số dòng ngoài) | bên ngoài ít dòng, bên trong có index |
| **Hash Join** | băm bảng nhỏ vào bộ nhớ (`Hash`), duyệt bảng lớn để dò | không có index, bảng nhỏ vừa `work_mem` |
| **Merge Join** | hai phía đã sắp theo khóa, trộn một lượt | hai phía đã có thứ tự (index, Sort) |

Nested Loop trong ví dụ: `u.id <= 5` cho 5 dòng ngoài; trong là Bitmap Heap Scan với `loops=5`, mỗi loop 20 dòng (`rows=20.00 loops=5`) → 100 dòng ra, `Heap Blocks: exact=100`.

## 5. Bộ nhớ và `work_mem`
- **Sort** hiện `Sort Method: quicksort Memory: …` (vừa RAM) hoặc `external merge Disk: …kB` (tràn ra file tạm, kèm `temp read/written` ở `Buffers`). Đo: sắp 400 000 dòng `(amount, id)`: `Memory: 21664kB` khi đủ chỗ, nhưng chỉ `Disk: 7072kB` khi tràn. **Trong RAM tốn gấp ~3 lần so với trên đĩa**, và ngưỡng chuyển đổi đo được là `work_mem = 19MB` (18MB vẫn tràn).
- **Hash** hiện `Batches: N`. `Batches: 1` = băm trọn trong RAM. `Batches > 1` = chia thành N phần ghi ra đĩa; **cả phía quét (probe) cũng bị ghi ra file tạm**. Đo với `work_mem = 64kB`: `Batches: 8`, `temp written=1081` page, nhiều hơn hẳn 128 page của bảng `u`.
- Lệnh `SET work_mem = '64MB'` đổi cho session; đừng đổi toàn server để chữa một query (P10a, O-tier).

## 6. Ước lượng sai
Cặp `rows=` (ước lượng) và `actual rows=` lệch ≥ 10× là dấu hiệu chính của plan tồi. Ví dụ ở `o`: `WHERE status = 'pending' AND amount = 0` ước lượng **4** dòng, thực tế **400** (100×): planner coi hai điều kiện độc lập (1% × 0.1% × 400 000 = 4) trong khi chúng tương quan. Hệ quả: chọn join/scan sai. Sửa bằng thống kê (P04).

## Bẫy hay gặp
1. Quên nhân `loops`; đọc thời gian `actual time` của node trong vòng lặp như tổng.
2. `EXPLAIN ANALYZE` trên `UPDATE/DELETE/INSERT` không bọc transaction.
3. So `cost` giữa hai plan khác truy vấn, hoặc coi cost là mili-giây.
4. Chỉ nhìn node trên cùng; lỗi thường nằm ở node có ước lượng lệch sâu bên dưới.
5. Kết luận từ lần chạy đầu: cache lạnh làm `read` cao, lần sau `hit`. Chạy 2–3 lần, so `BUFFERS` tổng (hit + read).
6. Plan trên bảng 10k dòng không giống plan trên 1M (xem ex09).

## Đo bằng gì
- `EXPLAIN (ANALYZE, BUFFERS)`; `pg_stats` (`correlation`, `n_distinct`); `SET work_mem`; `SET enable_seqscan = off` (chỉ để thử nghiệm, không dùng làm cách sửa).
- Phép đo "hit" chỉ nói cache của Postgres; cache của OS vẫn có thể che đĩa thật.
