# F04 · Aggregates

Đọc khoảng 10 phút. Mọi ví dụ chạy trên `shop_s`.

## Mục tiêu: sau buổi này bạn làm được
- Gộp dòng theo nhóm bằng `GROUP BY` và tính `count`, `sum`, `avg`, `min`, `max` cho từng nhóm.
- Phân biệt lọc **dòng** (`WHERE`) với lọc **nhóm** (`HAVING`).
- Đếm nhiều điều kiện trong cùng một query bằng `FILTER (WHERE …)`.
- Chọn đúng giữa `count(*)`, `count(col)` và `count(DISTINCT col)`.
- Ghép nhiều giá trị của một nhóm thành chuỗi (`string_agg`) hoặc mảng (`array_agg`).

---

## 1. `GROUP BY`: mỗi nhóm thành một dòng
```sql
SELECT status, count(*) AS n
FROM orders
GROUP BY status;          -- 6 nhóm → 6 dòng
```
**Quy tắc vàng:** mỗi cột trong `SELECT` phải thuộc một trong hai loại: **nằm trong `GROUP BY`**, hoặc **nằm trong một hàm aggregate**.
```sql
SELECT status, user_id, count(*) FROM orders GROUP BY status;
-- ERROR: column "orders.user_id" must appear in the GROUP BY clause or be used in an aggregate function
```
Lý do: mỗi nhóm `status` chứa hàng nghìn `user_id` khác nhau, nên Postgres không biết phải hiển thị `user_id` nào.

Có thể nhóm theo **nhiều cột** hoặc theo **biểu thức**:
```sql
SELECT country, (deleted_at IS NULL) AS active, count(*) FROM users GROUP BY country, active;
```

## 2. Thứ tự logic (bổ sung cho F01)
```
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```
- `WHERE` chạy **trước** khi gộp nhóm: lọc từng dòng, và không dùng được hàm aggregate.
- `HAVING` chạy **sau** khi gộp nhóm: lọc từng nhóm, và dùng được `count(*)`, `sum(...)`.

```sql
-- Khách có từ 50 đơn đã giao trở lên
SELECT user_id, count(*) AS n
FROM orders
WHERE status = 'delivered'        -- lọc dòng: chỉ giữ đơn đã giao
GROUP BY user_id
HAVING count(*) >= 50             -- lọc nhóm: chỉ giữ khách có ≥ 50 đơn như vậy
ORDER BY n DESC;
```
Điều kiện nào lọc được ở mức dòng thì đặt vào `WHERE`. Cách này vừa đúng nghĩa, vừa nhanh hơn, vì Postgres bỏ dòng sớm, trước khi phải gộp.

Trong Postgres, `GROUP BY` và `ORDER BY` dùng được alias hoặc số thứ tự cột (`GROUP BY 1`). Riêng `HAVING` thì **không** dùng được alias.

## 3. `count(*)`, `count(col)` và `count(DISTINCT col)`
| Biểu thức | Đếm cái gì |
|---|---|
| `count(*)` | Số dòng |
| `count(col)` | Số dòng có `col` khác NULL (đã học ở F03) |
| `count(DISTINCT col)` | Số **giá trị khác nhau** của `col`, không tính NULL |

```sql
SELECT count(*), count(user_id), count(DISTINCT user_id) FROM events;
-- 32363 sự kiện, 22597 sự kiện có user đăng nhập, 991 user khác nhau
```

## 4. `FILTER (WHERE …)`: nhiều phép đếm trong một lần quét
```sql
SELECT method,
       count(*)                                     AS total,
       count(*) FILTER (WHERE status = 'failed')    AS failed,
       sum(amount) FILTER (WHERE status = 'succeeded') AS collected
FROM payments
GROUP BY method;
```
`FILTER` chỉ áp dụng cho **đúng hàm aggregate đứng trước nó**. Các cột khác trong cùng query vẫn tính trên toàn bộ dòng của nhóm.
Cách viết kiểu cũ, chạy được trên mọi DB, là `sum(CASE WHEN status = 'failed' THEN 1 ELSE 0 END)`. Trong Postgres, `FILTER` gọn và dễ đọc hơn.

Tính tỉ lệ thì nhớ bẫy chia số nguyên (F02), vì `count()` trả về `bigint`:
```sql
round(count(*) FILTER (WHERE status = 'failed') * 100.0 / count(*), 2)
```

## 5. NULL trong `GROUP BY`
Mọi dòng có giá trị NULL được gom vào **một nhóm chung**. Ở đây NULL được coi là "giống nhau", khác với phép `=`.
```sql
SELECT discount_code, count(*) FROM orders GROUP BY discount_code;   -- có 1 dòng discount_code = NULL
```
Muốn hiển thị nhãn dễ đọc thay cho NULL thì dùng `coalesce(discount_code, '…')`.

## 6. `string_agg` và `array_agg`
```sql
SELECT order_id, string_agg(product_id::text, ',' ORDER BY line_no) AS products
FROM order_items WHERE order_id <= 3 GROUP BY order_id;
-- 1 | 39,100,28,159
```
- `string_agg(text, separator ORDER BY …)` nhận vào **text**, nên phải ép kiểu số bằng `::text`.
- `array_agg(col ORDER BY …)` trả về một mảng, ví dụ `{39,100,28,159}`.
- Phải có `ORDER BY` **bên trong** hàm. Nếu thiếu, thứ tự các phần tử không được bảo đảm.

## 7. `date_trunc`: nhóm theo tháng hoặc ngày
```sql
SELECT date_trunc('month', timestamp '2026-09-17 13:45');   -- 2026-09-01 00:00:00
```
Nhóm theo tháng **giờ Việt Nam** thì phải đổi sang giờ VN **trước**, rồi mới cắt:
```sql
date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')
```
Nếu cắt thẳng `date_trunc('month', created_at)` thì Postgres cắt theo TimeZone của phiên (đang là UTC). Khi đó các đơn đặt từ 0h đến 7h sáng ngày 1 (giờ VN) bị tính vào tháng trước.

---

## Bẫy hay gặp

| # | Sai | Đúng | Vì sao |
|---|---|---|---|
| 1 | `WHERE count(*) >= 5` | `HAVING count(*) >= 5` | `WHERE` chạy trước khi gộp nhóm, nên lúc đó chưa có `count` |
| 2 | `count(*) FILTER (WHERE …) / count(*)` | `… * 100.0 / count(*)` | `bigint / bigint` là chia số nguyên, kết quả ra 0 |
| 3 | `count(user_id)` để đếm số user | `count(DISTINCT user_id)` | `count(col)` đếm số dòng, không đếm số giá trị khác nhau |
| 4 | `HAVING status = 'delivered'` | `WHERE status = 'delivered'` | Chạy được, nhưng lọc muộn và khó đọc. Điều kiện trên dòng thì đặt vào `WHERE` |
| 5 | `date_trunc('month', created_at)` khi báo cáo theo giờ VN | `date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')` | Cắt theo UTC thì đơn ở ranh giới tháng bị lệch |

## Postgres-specific
- **MySQL** (khi tắt `ONLY_FULL_GROUP_BY`) cho phép chọn cột không có trong `GROUP BY` và trả về một giá trị bất kỳ. **Postgres báo lỗi**, và đó là điều tốt. Có một ngoại lệ: nếu bạn `GROUP BY` theo khóa chính của bảng thì được phép chọn mọi cột khác của bảng đó.
- `FILTER (WHERE …)` là chuẩn SQL, nhưng MySQL và SQL Server **không có**. Ở hai hệ đó phải dùng `CASE` bên trong hàm aggregate.
- MySQL dùng `GROUP_CONCAT`, SQL Server dùng `STRING_AGG(...) WITHIN GROUP (ORDER BY …)`.
