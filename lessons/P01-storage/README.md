# P01 · Storage: heap, page, TOAST

Đọc khoảng 10 phút. Ví dụ chạy trên `shop_s` (đo thật trên Postgres 18.6). Muốn xem nội dung page, cần `CREATE EXTENSION pageinspect;` (superuser, đã có trong `setup.sql` của bài).

## Mục tiêu: sau buổi này bạn làm được
- Giải thích một dòng nằm ở đâu trên đĩa: **heap**, **page 8 KB**, **line pointer**, **tuple header**, **ctid**.
- Tính được một bảng sẽ chiếm bao nhiêu MB từ số dòng, bằng số đo thật chứ không đoán.
- Giải thích **TOAST** (nén + tách giá trị lớn ra bảng phụ) và biết khi nào nó làm query chậm.
- Biết `fillfactor` và **HOT update** liên quan nhau thế nào, và vì sao thứ tự cột làm bảng to hơn.

---

## 1. Heap và page
Bảng Postgres là một **heap**: file gồm các **page** 8 KB (`current_setting('block_size')`), không có thứ tự nào đảm bảo. Mỗi page:

```
| page header (24 B) | line pointer 1 | line pointer 2 | ... →  khoảng trống  ← ... | tuple 2 | tuple 1 |
```
- **Line pointer** (4 B/dòng) trỏ tới vị trí tuple trong page. Chúng mọc từ đầu page, tuple mọc từ cuối page.
- **Tuple** = tuple header (23 B + căn lề, thường 24 B; thêm null bitmap thì tới 32 B) + dữ liệu các cột.

```sql
SELECT current_setting('block_size') AS block_size,
       pg_relation_size('orders') / 8192 AS pages, count(*) AS n FROM orders;   -- 120 trang, 10 000 dòng
SELECT ctid, id FROM orders WHERE id <= 3;                                      -- (0,1) (0,2) (0,3)
SELECT lp, lp_off, lp_len, t_hoff FROM heap_page_items(get_raw_page('orders', 0)) LIMIT 3;
-- lp=1 lp_off=8104 lp_len=88 t_hoff=32 · lp=2 lp_off=8008 lp_len=96 …  (tuple đặt từ cuối page ngược lên)
```
- `ctid = (số page, số slot)`: địa chỉ vật lý của **phiên bản** dòng. `UPDATE` tạo phiên bản mới nên **ctid đổi** (P07). Không dùng ctid làm khóa.
- `orders` ở `shop_s`: 983 040 B / 10 000 dòng ≈ **98 B/dòng**, ≈ 83 dòng/page. Cùng bảng ở `shop_m`: 11 929 page / 1 000 000 dòng ≈ 98 B/dòng. Tuyến tính theo N, nên **dung lượng bảng ước lượng được từ bytes/dòng**.
- Đọc 1 dòng = đọc **cả page 8 KB**. Mọi chi phí I/O của Postgres đếm bằng page (P03 sẽ đo bằng `BUFFERS`).

## 2. Kích thước: đo bằng gì
| hàm | trả về |
|---|---|
| `pg_relation_size('t')` | chỉ file heap (main fork) |
| `pg_table_size('t')` | heap + TOAST + FSM + VM |
| `pg_indexes_size('t')` | tất cả index của bảng |
| `pg_total_relation_size('t')` | tất cả những thứ trên |

Hỏi "bảng này bao nhiêu GB" mà không nói rõ loại nào là hỏi chưa xong: `pg_relation_size` bỏ sót TOAST và index.

## 3. TOAST
Giá trị lớn không nằm vừa page (tuple tối đa < 8 KB). Khi tuple vượt khoảng **2 KB** (`TOAST_TUPLE_THRESHOLD`), Postgres lần lượt: (1) **nén** cột lớn (`pglz`, hoặc `lz4` nếu cấu hình); (2) nếu vẫn lớn, **tách ra bảng TOAST** `pg_toast.pg_toast_<oid>`, mỗi giá trị cắt thành chunk ~2 KB, trong heap chỉ còn con trỏ 18 B.

Đo trên `lab.p01.docs` (300 dòng mỗi loại):

| kind | độ dài | `pg_column_size` | nằm ở đâu |
|---|---|---|---|
| short | 96 B | 97 B | inline trong heap |
| medium | 6 270 B (lặp nhiều) | 117 B | **nén**, vẫn inline |
| long | 60 800 B (md5 ngẫu nhiên) | 60 800 B | **không nén được** → ra TOAST: heap 14 page, TOAST 2 300 page |

```sql
SELECT pg_column_size(body) AS stored, octet_length(body) AS raw, pg_column_compression(body) FROM p01.docs WHERE id IN (1, 1001, 2001);
```
Hệ quả thực tế:
- `SELECT id FROM docs` không đụng tới TOAST. `SELECT *` hay `SELECT body` thì phải đọc chunk (nhiều page hơn nhiều, bẫy `SELECT *` ở P09).
- Hàm cần giá trị đầy đủ (`length(body)`, `lower(body)`) phải **detoast** (đọc + giải nén). `octet_length(body)` thì không: nó đọc kích thước từ con trỏ (ex05).
- `UPDATE` một cột nhỏ của dòng có TOAST: giá trị TOAST **không** bị ghi lại nếu cột đó không đổi. Ghi lại `body` thì ghi lại cả 60 KB.
- jsonb lớn cũng bị TOAST. `attributes->>'color'` vẫn phải detoast cả jsonb nếu nó đã ra ngoài (I07, P05).

## 4. Căn lề (alignment) làm bảng to hơn
Mỗi kiểu có alignment: `bigint` 8, `int` 4, `smallint` 2, `boolean` 1. Postgres chèn byte đệm để cột 8 B nằm ở địa chỉ chia hết cho 8. Xen kẽ `boolean, bigint, boolean, bigint…` sinh nhiều byte đệm. Xếp cột **rộng trước, hẹp sau** (hoặc nhóm cột cùng cỡ) thì bảng gọn hơn. Chỉ làm được lúc thiết kế: đổi thứ tự cột sau này là rewrite cả bảng (ex06).

## 5. fillfactor và HOT
- `fillfactor` (mặc định 100 cho bảng) = % page được lấp khi INSERT; phần còn lại để dành cho phiên bản mới của `UPDATE`.
- **HOT update** (heap-only tuple): nếu `UPDATE` không đổi cột nào có index **và** page còn chỗ trống cho phiên bản mới, Postgres không cần thêm entry vào mọi index. Rẻ hơn hẳn và để lại ít bloat.
- Bảng bị UPDATE nhiều mà page đầy 100% thì phiên bản mới phải sang page khác → không HOT. `ALTER TABLE … SET (fillfactor = 70)` chỉ áp dụng cho page **mới**; page cũ giữ nguyên cho tới khi rewrite (`CLUSTER`, `VACUUM FULL`, `ALTER … TYPE`).
- Kiểm tra: tuple có cờ `HEAP_ONLY_TUPLE` (`t_infomask2 & 32768`) là phiên bản HOT.

## Bẫy hay gặp
1. `pg_relation_size` hoặc `reltuples` thay cho tổng dung lượng: bỏ sót TOAST, index. `reltuples` chỉ là ước lượng từ lần `ANALYZE`/`VACUUM` gần nhất.
2. `SELECT *` trên bảng có cột lớn: kéo cả TOAST dù chỉ cần vài cột.
3. Đặt cột `boolean`/`smallint` xen giữa các cột `bigint`.
4. Đổi `fillfactor` mà không rewrite rồi tưởng UPDATE đã HOT.
5. Ngoại suy dung lượng bằng "số dòng × tổng độ rộng cột": quên tuple header, line pointer, căn lề, fillfactor (ước lượng sẽ thấp hơn thực tế).

## Đo bằng gì
- `pg_relation_size`, `pg_table_size`, `pg_total_relation_size`, `pg_size_pretty`.
- `pageinspect`: `get_raw_page`, `heap_page_items`, `page_header`. `pg_column_size`, `pg_column_compression`.
- Giới hạn của phép đo: kích thước là số tất định theo dữ liệu nên chạy trên máy nào cũng như nhau (cùng phiên bản Postgres, `block_size = 8192`). Chỉ thời gian mới phụ thuộc máy.
