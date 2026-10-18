# F08 · DML: INSERT / UPDATE / DELETE / UPSERT / MERGE

Đọc khoảng 8 phút. Ví dụ chạy trên DB **`lab`**, schema `f08` (chạy `setup.sql`). Bài này **ghi dữ liệu**, nên không dùng `shop_*`.

## Mục tiêu: sau buổi này bạn làm được
- Chèn dữ liệu bằng `INSERT … VALUES` nhiều dòng và `INSERT … SELECT`, lấy lại giá trị sinh ra bằng `RETURNING`.
- Sửa dữ liệu từ bảng khác bằng `UPDATE … FROM`, và biết bẫy khi **nhiều dòng khớp**.
- Xóa có điều kiện theo bảng khác bằng `DELETE … USING`, kể cả xóa dòng trùng.
- Viết upsert với `ON CONFLICT DO NOTHING / DO UPDATE`, hiểu `EXCLUDED`.
- Dùng `MERGE` cho đồng bộ "có thì sửa, chưa có thì thêm, hết hàng thì tắt", và biết khi nào nên chọn `ON CONFLICT`.

---

## 1. `INSERT`
```sql
INSERT INTO f08.products (sku, name, price, stock)      -- luôn liệt kê cột
VALUES ('P-011','Đế tản nhiệt',150000,30),
       ('P-012','Pad chuột',   60000, 0)                -- nhiều dòng một câu lệnh
RETURNING id, sku;                                       -- trả về dòng vừa chèn
```
- **Luôn liệt kê cột.** `INSERT INTO t VALUES (…)` phụ thuộc thứ tự cột hiện tại, thêm cột sau này là vỡ.
- Cột bị bỏ qua nhận `DEFAULT` (identity, `now()`…). Cột `NOT NULL` không có default mà bỏ qua thì lỗi.
- `INSERT … SELECT` chèn kết quả một query. Đây là cách nạp dữ liệu hàng loạt từ bảng khác.
- Nhiều dòng trong một câu lệnh **nhanh hơn nhiều** so với mỗi dòng một câu lệnh (đo ở P10b).
- `RETURNING` hoạt động với cả `INSERT`, `UPDATE`, `DELETE`, `MERGE`. Tránh phải `SELECT` lại để biết `id` mới.

## 2. `UPDATE`
```sql
UPDATE f08.products SET price = round(price * 1.10, 0), updated_at = now()
WHERE is_active AND price < 500000;
```
- **Quên `WHERE` là sửa cả bảng.** Thói quen an toàn: chạy `SELECT` với đúng `WHERE` đó trước, rồi trong `BEGIN … ROLLBACK` thử, xem số dòng ("UPDATE n"), đúng mới `COMMIT`.
- Vế phải của `SET` luôn thấy **giá trị cũ** của dòng. `SET a = b, b = a` hoán đổi được.
- Postgres 18 cho `RETURNING old.cột, new.cột` để lấy cả giá trị trước và sau khi sửa:
  `UPDATE … RETURNING old.price AS gia_cu, new.price AS gia_moi;`

### `UPDATE … FROM`: sửa theo bảng khác
```sql
UPDATE f08.products p
SET stock = f.qty
FROM f08.stock_feed f
WHERE f.sku = p.sku;
```
- Đây không phải chuẩn SQL mà là mở rộng của Postgres (dùng thay cho correlated subquery khi cần nhiều cột).
- **Bẫy:** nếu một dòng `p` khớp **nhiều** dòng `f`, Postgres **không báo lỗi**, chỉ áp dụng **một** dòng khớp, và không đảm bảo là dòng nào. Ví dụ `P-002` có hai dòng trong feed: kết quả có thể là 12 hoặc 10 (mình đã thử, ra 12 là bản **cũ hơn**). Luôn gộp/chọn **một dòng duy nhất mỗi khóa** trước khi `FROM`.
- Chọn "dòng mới nhất mỗi khóa" kiểu Postgres: `SELECT DISTINCT ON (sku) … ORDER BY sku, received_at DESC`.

## 3. `DELETE … USING`
```sql
DELETE FROM f08.cart_items c
USING f08.products p
WHERE p.id = c.product_id AND NOT p.is_active;
```
- `USING` là cú pháp của Postgres để nối thêm bảng khác (như `FROM` của `UPDATE`).
- **Xóa dòng trùng, giữ một bản:** nối bảng với chính nó và xóa bản "đứng sau":
  `DELETE FROM t a USING t b WHERE a.key = b.key AND (b.created_at, b.id) < (a.created_at, a.id)`.
  So sánh **row** `(x, y) < (u, v)` so cột đầu trước, hòa thì so cột sau, rất tiện cho "hòa thì lấy id nhỏ".
- `DELETE` không có `WHERE` xóa sạch bảng (chậm và sinh nhiều dead tuple). Muốn xóa sạch hãy dùng `TRUNCATE` (nói ở P07).

## 4. Upsert: `INSERT … ON CONFLICT`
```sql
INSERT INTO f08.daily_stats (day, orders, revenue)
VALUES ('2026-10-16', 3, 1500000)
ON CONFLICT (day) DO UPDATE
  SET orders  = f08.daily_stats.orders  + EXCLUDED.orders,
      revenue = f08.daily_stats.revenue + EXCLUDED.revenue;
```
- `ON CONFLICT (cột)` chỉ rõ ràng buộc unique/PK nào gây xung đột. Cột đó phải có unique index.
- `DO NOTHING`: bỏ qua dòng xung đột. `DO UPDATE SET …`: sửa dòng đã có.
- `EXCLUDED` là dòng bạn **định chèn**. Tên bảng là dòng **đã có**. Cộng dồn dùng cả hai, như ví dụ trên.
- `RETURNING` chỉ trả các dòng **thực sự chèn hoặc sửa**. Dòng bị `DO NOTHING` bỏ qua thì không có trong kết quả.
- **Bẫy:** trong **một** câu `INSERT … DO UPDATE`, nếu hai dòng định chèn cùng khóa thì lỗi
  `ON CONFLICT DO UPDATE command cannot affect row a second time`. Phải gộp trước (`GROUP BY` hoặc `DISTINCT ON`). `DO NOTHING` thì không bị lỗi này.
- Đây là cách **an toàn khi nhiều session chạy cùng lúc**: Postgres đảm bảo kết quả là "chèn hoặc sửa", không bị lỗi do race.

## 5. `MERGE` (Postgres 15+)
```sql
MERGE INTO f08.products p
USING (SELECT DISTINCT ON (sku) sku, name, qty, price
       FROM f08.stock_feed ORDER BY sku, received_at DESC) f
  ON f.sku = p.sku
WHEN MATCHED AND f.qty = 0 THEN UPDATE SET is_active = false, stock = 0
WHEN MATCHED               THEN UPDATE SET stock = f.qty
WHEN NOT MATCHED           THEN INSERT (sku, name, price, stock) VALUES (f.sku, f.name, f.price, f.qty);
```
- Mỗi dòng nguồn được xét theo thứ tự các mệnh đề `WHEN`; mệnh đề **đầu tiên** khớp (kể cả điều kiện `AND …`) thắng.
- Nguồn phải có **tối đa một dòng khớp mỗi dòng đích**, nếu không lỗi `MERGE command cannot affect row a second time`. Khác với `UPDATE … FROM` (im lặng chọn bừa).
- `MERGE` làm được 3 việc trong một câu: sửa, chèn, **xóa** (`WHEN MATCHED THEN DELETE`). Postgres 17+ còn có `WHEN NOT MATCHED BY SOURCE` (dòng đích không còn trong nguồn) và hàm `merge_action()`.
- **`MERGE` vs `ON CONFLICT`:** đồng bộ dữ liệu theo lô với nhiều nhánh → `MERGE`. Upsert "chèn hoặc sửa" mà **nhiều session ghi đồng thời** → `ON CONFLICT`, vì `MERGE` có thể vẫn gặp lỗi unique violation khi hai session cùng chèn một khóa.

## 6. Bẫy hay gặp
1. `UPDATE`/`DELETE` quên `WHERE`, hoặc `WHERE` viết sai nên sửa nhiều hơn dự định. Cách chữa: `BEGIN`, xem "UPDATE n", `ROLLBACK`.
2. `UPDATE … FROM` với nguồn có khóa trùng: kết quả không xác định, **không có lỗi nào báo**.
3. `ON CONFLICT DO UPDATE` với batch có khóa trùng: lỗi "cannot affect row a second time".
4. `DELETE` bằng `NOT IN (subquery có NULL)`: xóa **0 dòng** (đã gặp ở F06). Dùng `NOT EXISTS` hoặc `USING`.
5. Ngày theo múi giờ: nhóm theo ngày giờ VN phải `AT TIME ZONE 'Asia/Ho_Chi_Minh'` trước khi `::date` (ex07).

## 7. Quy mô (đọc để dùng ở bonus)
`UPDATE` trong Postgres **không sửa tại chỗ**: nó ghi một **phiên bản dòng mới** và để lại phiên bản cũ (dead tuple) cho đến khi `VACUUM`. Sửa cả bảng 1 triệu dòng làm bảng **phình gần gấp đôi**. `DELETE` thì không trả lại chỗ ngay. Chi tiết ở P07; ở đây chỉ cần nhớ "UPDATE hàng loạt không rẻ".
