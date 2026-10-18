# P02 · B-tree index

Đọc khoảng 10 phút. Mọi con số đo trên `shop_m` (1M đơn), Postgres 18.6 trong Docker, `shared_buffers = 256MB`. Đo `BUFFERS` (hit + read) vì số page ổn định; thời gian chỉ để tham khảo, máy bạn sẽ khác.

## Mục tiêu: sau buổi này bạn làm được
- Giải thích B-tree: vì sao tra cứu là O(log n) và cực nhỏ ở thực tế (3–4 page cho 1M dòng).
- Đặt **thứ tự cột** trong index composite đúng theo quy tắc: equality trước, range sau; biết khi nào index phục vụ được `ORDER BY` mà không cần Sort.
- Dùng **covering index** (`INCLUDE`) để có Index Only Scan, **partial index** để thu nhỏ index, **expression index** cho điều kiện bọc hàm.
- Biết các bẫy: `LIKE 'abc%'`, hàm bọc cột, index thừa, chi phí ghi.

---

## 1. B-tree là gì
Cây cân bằng gồm các page 8 KB: **root** → các tầng internal → **leaf** (chứa `key + ctid` đã sắp xếp, các leaf nối nhau hai chiều). Tra cứu đi từ root xuống leaf, tốn `level + 1` page, rồi 1 page heap.

Đo trên `orders_pkey` (PK `bigint`):

| scale | N | index page | level (`bt_metap`) | bytes/key | buffers cho `WHERE id = 77` |
|---|---|---|---|---|---|
| s | 10 000 | 30 | 1 | 24.6 | 3 |
| m | 1 000 000 | 2 745 (22.5 MB) | 2 | 22.5 | 4 |

Dữ liệu tăng 100 lần, số page chạm tăng từ 3 lên 4. Mỗi page chứa hàng trăm key nên cây rất thấp. Đối chiếu với không index: `WHERE user_id = 77` ở `m` phải đọc **11 929 page** (Seq Scan), 23 ms; ở `s` 120 page, 0.7 ms. Đây là O(n) với n tính theo page, còn index là O(log n).

Index không miễn phí: mỗi `INSERT`/`UPDATE` đổi cột index phải ghi thêm vào mọi index (đo chi tiết ở P10b), và index chiếm chỗ (22.5 MB cho PK `orders`, bằng 23% heap 97.7 MB).

## 2. Index composite: thứ tự cột
Index `(a, b, c)` sắp theo `a`, trong cùng `a` sắp theo `b`, rồi `c`. Hệ quả:
- Dùng tốt cho điều kiện trên **tiền tố**: `a`; `a, b`; `a, b, c`. Cột đứng sau chỉ hữu ích khi các cột trước nó đã bị **equality** ghim lại.
- Quy tắc kinh nghiệm: **equality trước, range sau, cột để ORDER BY sau cùng.** Cột có range đặt sớm làm "cắt cụt" khả năng dùng các cột sau.
- Đo với `WHERE user_id = 4242 AND created_at >= '2026-01-01' AND created_at < '2026-04-01'` (4 dòng):

| index | buffers |
|---|---|
| `(user_id, created_at)` | **7** |
| `(created_at, user_id)` | 524 (quét hết khoảng `created_at` rồi mới lọc `user_id`) |
| không index | 11 929 |

- `ORDER BY` cũng đọc theo thứ tự index. `WHERE user_id = 4242 ORDER BY created_at DESC LIMIT 5`: với `(user_id)` phải Sort (top-N heapsort, 34 buffers); với `(user_id, created_at)` **không có Sort**, đọc ngược (Index Scan Backward), 8 buffers.
- **Skip scan (Postgres 18):** index `(status, user_id)` giờ vẫn dùng được cho `WHERE user_id = 4242` bằng cách nhảy qua từng giá trị `status` (đo: 13 lần tìm, 79 buffers). Chỉ hợp lý khi cột đứng đầu có **rất ít giá trị phân biệt**. Với cột đứng đầu có nhiều giá trị (như `created_at`) vẫn là Seq Scan. Từ 17 trở xuống chưa có tính năng này.

## 3. Covering index và Index Only Scan
`CREATE INDEX ON orders (user_id) INCLUDE (total_amount)` đặt thêm `total_amount` vào leaf (không làm key sắp xếp). Query chỉ cần các cột này sẽ có **Index Only Scan**, không đụng heap:

| index | plan | buffers (tổng 55 831 dòng của 1 000 user) |
|---|---|---|
| `(user_id)` | Bitmap Heap Scan | 11 445 |
| `(user_id) INCLUDE (total_amount)` | Index Only Scan, `Heap Fetches: 0` | **222** |

Điều kiện: page heap phải **all-visible** trong visibility map (VACUUM đặt). Bảng vừa bị UPDATE nhiều thì `Heap Fetches` tăng, lợi thế mất dần (P07). `INCLUDE` đắt bằng dung lượng index: chỉ thêm cột của query nóng.

## 4. Partial index
`CREATE INDEX … WHERE điều_kiện` chỉ chứa các dòng thỏa điều kiện. Đơn chưa hoàn tất (pending/paid/shipped) chỉ 3.3% bảng:

| index | kích thước | buffers cho `status IN ('pending','paid') ORDER BY created_at LIMIT 50` |
|---|---|---|
| `(created_at)` đầy đủ | 22.5 MB | 218 |
| `(created_at) WHERE status IN ('pending','paid','shipped')` | **0.76 MB** | **46** |
| không index | | 12 013 (Seq Scan + Sort) |

Planner chỉ dùng partial index khi **chứng minh được** điều kiện query suy ra điều kiện index: `status = 'pending'` trong index không phục vụ query `IN ('pending','paid')`.

## 5. Expression index
Điều kiện bọc hàm lên cột (`lower(email)`, `(created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date`) không dùng được index trên cột gốc. Tạo index **trên chính biểu thức**, và query phải viết **đúng biểu thức đó**:
```sql
CREATE INDEX ON orders (((created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date));
```
Biểu thức phải **IMMUTABLE**. `created_at::date` (phụ thuộc `TimeZone` của session) là STABLE nên bị từ chối; `AT TIME ZONE 'Asia/Ho_Chi_Minh'` với hằng thì được. Đo: đơn của ngày 11/11/2025 (6 516 dòng): 88 buffers với index, thay vì quét 11 929 page.

## 6. `LIKE 'abc%'` và collation
B-tree mặc định sắp theo quy tắc `en_US.utf8` (DB này), không phải theo từng byte, nên `LIKE 'hung.pham88%'` không dùng được: Seq Scan 1 526 page. Index `(email text_pattern_ops)` sắp theo byte: 5 buffers. `text_pattern_ops` không giúp `<`, `>`, `ORDER BY` thường; cần cả hai index nếu dùng cả hai kiểu.

## Bẫy hay gặp
1. Cột range đặt trước cột equality; bỏ quên `ORDER BY` trong index.
2. Tạo `(a)` rồi `(a, b)` rồi `(a, b, c)`: hai index đầu là thừa (tiền tố). Mỗi index thừa tốn chỗ và làm chậm mọi ghi (ex08).
3. Hàm bọc cột, cast ngầm: index trên cột gốc bị bỏ qua (P09).
4. Index low-cardinality (`status` có 6 giá trị) hầu như vô dụng trừ khi lọc giá trị hiếm; partial index thường tốt hơn.
5. Quên rằng khóa ngoại **không tự có index** ở bên con (F09); `shop_*` cố ý không có index nào ngoài PK/UNIQUE.
6. Index Only Scan nhưng `Heap Fetches` cao vì visibility map cũ.

## Đo bằng gì
- `EXPLAIN (ANALYZE, BUFFERS)`: số buffers (hit + read) và dòng `Index Searches` (Postgres 18).
- `pg_relation_size('index')`, `bt_metap('index')` (pageinspect) cho level.
- Giới hạn phép đo: số buffers ổn định giữa các máy; thời gian không. `shared_buffers` 256 MB với `shop_m` 900 MB: hit/read trộn lẫn nên chỉ so tổng.
