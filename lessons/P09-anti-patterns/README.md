# P09 · Query anti-patterns

Đọc khoảng 10 phút. Mọi ví dụ trên `shop_m` (1M đơn) trừ ex05 (`lab.p09`), Postgres 18.6. Số đo là `BUFFERS` (hit + read), ổn định giữa các máy; thời gian chỉ để tham khảo.

## Mục tiêu: sau buổi này bạn làm được
- Nhận ra 8 mẫu truy vấn chạy tốt ở 10k dòng nhưng sụp ở 1M+, và viết lại kèm index đúng.
- Giải thích **vì sao** planner không dùng được index trong từng mẫu (không phải thuộc lòng "đừng làm X").
- Đo hiệu quả trước/sau bằng `EXPLAIN (ANALYZE, BUFFERS)`, kể cả chi phí gửi dữ liệu (`SERIALIZE`).

---

## Bảng tổng kết 8 mẫu (đo trên `shop_m`)
| # | anti-pattern | vì sao tệ | sửa | trước → sau (buffers) |
|---|---|---|---|---|
| 1 | hàm bọc cột: `created_at::date = X` | index trên `created_at` không khớp biểu thức | khoảng nửa mở `>= X AND < X+1` + index | 11 929 → **14** |
| 2 | cast ngầm phía cột: `user_id::text = '4242'` | cột bị biến đổi, mất index | hằng cùng kiểu cột: `user_id = 4242` | 11 929 → **34** |
| 3 | `OR` giữa hai bảng sau join | không tách được hai đường index | `UNION` hai nhánh index-friendly | cả bảng → **132** |
| 4 | `OFFSET` sâu | đọc rồi bỏ N dòng | keyset pagination | 14 199 → **4** |
| 5 | `SELECT *` với cột lớn | kéo TOAST về client | chọn cột cần | 3 225 buffers + 17.8 MB → **72**, 7 kB |
| 6 | `COUNT(*)` chính xác để hiển thị | đọc cả bảng | `count` trên subquery `LIMIT 1001` | 45 243 → **335** |
| 7 | N+1 | N+1 vòng đi về, mỗi vòng một Seq Scan | một query `LATERAL` + index | ≈ 600 000 → **154** |
| 8 | `NOT IN (subquery)` | SubPlan + Materialize, nhạy NULL | `NOT EXISTS` / anti-join | cost 1.7 tỉ → **12 207** |

## Chi tiết

### 1–2. Đừng biến đổi cột, hãy biến đổi hằng
Index B-tree lưu **giá trị của cột**; điều kiện chỉ dùng được index khi so sánh trực tiếp cột đó với hằng/tham số. Hàm (`lower(email)`, `date_trunc`, `::date`, `::text`, `col + 1`) bọc cột là chặn. Hai cách chữa: (a) đẩy phép biến đổi sang phía hằng (khoảng thời gian, `user_id = 4242`); (b) nếu không sửa được query, **expression index** trên đúng biểu thức (P02). Cast ngầm thường đến từ driver/ORM gửi tham số sai kiểu: kiểm tra `EXPLAIN` xem có `::text` ở phía cột không.

### 3. OR
Trên **cùng một bảng**, `a = 1 OR b = 2` với index riêng cho `a` và `b` được xử lý bằng `BitmapOr`. Khi hai vế thuộc hai bảng của join, hoặc một vế bọc hàm, planner thường chịu Seq Scan. Tách bằng `UNION` (loại trùng) hoặc `UNION ALL` (nếu chắc không trùng).

### 4. OFFSET
`OFFSET N` buộc sinh N dòng rồi bỏ: chi phí O(N) kể cả có index (xem ex09). **Keyset**: lấy khóa sắp xếp của dòng cuối trang trước, truy vấn `WHERE (a, id) < (…) ORDER BY a DESC, id DESC LIMIT n` với index khớp. Chi phí O(log N + n).

### 5. SELECT *
Cột lớn (text/jsonb > ~2 KB) nằm ở TOAST (P01); `SELECT *` đọc cả chunk và gửi chúng qua mạng. **`EXPLAIN (ANALYZE)` thường không đo phần này** vì không detoast; dùng `EXPLAIN (ANALYZE, BUFFERS, SERIALIZE)` (Postgres 17+) để thấy `Serialization: output=17823kB`. Ngoài ra `SELECT *` chặn Index Only Scan và gãy khi schema thêm cột.

### 6. COUNT(*)
`count(*)` chính xác là O(số dòng thỏa), với MVCC phải kiểm tra tính hiển thị từng dòng (Index Only Scan chỉ giúp khi bảng được VACUUM). UI chỉ cần "≥ 1000?": đếm có chặn (`LIMIT 1001`); số gần đúng: `pg_class.reltuples` hoặc `EXPLAIN`; số chính xác thường xuyên: bảng tổng hợp/cache (R12).

### 7. N+1
App lặp qua kết quả của query đầu rồi chạy thêm một query cho mỗi dòng. Độ trễ = (N+1) × round-trip + mỗi query riêng. Gộp bằng `JOIN`, `IN (…)`, `= ANY($1)`, hoặc `LATERAL` cho "top-k mỗi nhóm" (I08).

### 8. NOT IN
`x NOT IN (SELECT y …)` cho kết quả **rỗng** nếu `y` có một NULL (vì `x <> NULL` là unknown), và planner chỉ băm được nếu subquery vừa `work_mem`; nếu không → `SubPlan` + `Materialize` lặp cho mỗi dòng ngoài. `NOT EXISTS` đúng nghĩa "không có dòng khớp" và thành anti-join.

## Bẫy hay gặp
1. "Đã có index mà vẫn Seq Scan": nhìn xem cột có bị bọc/cast không.
2. Tối ưu trên bảng 10k dòng: mọi thứ đều nhanh; luôn thử ở `m`.
3. Tin vào `EXPLAIN ANALYZE` của `SELECT *` khi cột lớn: thiếu `SERIALIZE`.
4. Keyset với khóa không duy nhất (trùng created_at): rớt hoặc lặp dòng.
5. Viết lại cho "đẹp" mà đổi ngữ nghĩa (UNION ALL gây trùng, bỏ join làm mất lọc FK).

## Đo bằng gì
- `EXPLAIN (ANALYZE, BUFFERS)` (+ `SERIALIZE` cho ex05). Check chạy DDL của bạn trong transaction rồi ROLLBACK, so **kết quả với query gốc** (`same()`) và ngưỡng buffers rộng.
- Giới hạn phép đo: số buffers ổn định; thời gian phụ thuộc máy. `shop_l` chưa verify.
