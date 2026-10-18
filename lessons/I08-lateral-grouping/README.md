# I08 · LATERAL, GROUPING SETS, pivot

Đọc khoảng 10 phút. Ví dụ chạy trên `shop_s` (bài 7 cần extension `tablefunc`: `setup.sql` cài giúp, chạy một lần).

## Mục tiêu: sau buổi này bạn làm được
- Dùng `LATERAL` để subquery bên phải tham chiếu cột của bảng bên trái (top-N mỗi nhóm, "dòng mới nhất mỗi khách").
- Phân biệt `CROSS JOIN LATERAL` (như INNER) với `LEFT JOIN LATERAL … ON true` (giữ dòng bên trái không có kết quả).
- Gom nhiều mức trong một lần quét bằng `GROUPING SETS`, `ROLLUP`, `CUBE`; dùng `grouping()` để phân biệt dòng tổng với NULL thật.
- Pivot (dòng → cột) bằng `count(*) FILTER (WHERE …)`, và bằng `crosstab()` của `tablefunc`.
- Nói được khi nào chọn LATERAL, khi nào chọn `row_number()`.

---

## 1. LATERAL
Subquery trong `FROM` bình thường **không** thấy cột của bảng đứng trước nó. Thêm `LATERAL` thì thấy, và nó chạy lại cho từng dòng bên trái.
```sql
-- 2 đơn mới nhất của mỗi khách (id ≤ 3)
SELECT u.id AS user_id, o.id AS order_id, o.created_at
FROM users u
CROSS JOIN LATERAL (
  SELECT id, created_at
  FROM orders
  WHERE user_id = u.id          -- tham chiếu u.id: chỉ hợp lệ nhờ LATERAL
  ORDER BY created_at DESC, id DESC
  LIMIT 2
) o
WHERE u.id <= 3
ORDER BY u.id, o.created_at DESC;
```
- Thiếu `LATERAL` → lỗi `invalid reference to FROM-clause entry for table "u"`.
- `ORDER BY … LIMIT` nằm **trong** subquery nên áp cho từng khách. Đặt `LIMIT` ngoài thì chỉ ra 2 dòng cho cả kết quả.
- `CROSS JOIN LATERAL` bỏ khách không có đơn nào (giống INNER JOIN). Muốn giữ họ: `LEFT JOIN LATERAL (…) o ON true`. `ON true` vì điều kiện nối đã nằm trong subquery.
- Hàm trả về tập hợp (`unnest`, `jsonb_array_elements`, `generate_series`) trong `FROM` tự động là LATERAL: `FROM products p, jsonb_object_keys(p.attributes) k` chính là cú pháp này.

**LATERAL hay `row_number()`?** Cả hai đều ra top-N mỗi nhóm.
- `row_number() OVER (PARTITION BY … )` (I03) đọc **toàn bộ** các dòng rồi mới cắt. Hợp khi nhóm ít hoặc bạn cần xếp hạng cho nhiều dòng.
- `LATERAL … LIMIT N` chạy N-dòng-đầu cho từng dòng bên trái. Với index đúng `(user_id, created_at DESC)` mỗi lần chỉ đọc vài dòng, nên nhanh khi **số khách ít** hoặc khi bạn đã lọc bảng bên trái. Nếu bên trái có hàng triệu dòng thì phải chạy hàng triệu lần subquery (ex09).

## 2. GROUPING SETS, ROLLUP, CUBE
Một lần quét, nhiều kiểu gom:
```sql
SELECT country, status, count(*)
FROM orders o JOIN users u ON u.id = o.user_id
WHERE u.country IN ('JP', 'SG')
GROUP BY GROUPING SETS ((country, status), (country), ());
```
| Viết tắt | Tương đương |
|---|---|
| `ROLLUP (a, b)` | `GROUPING SETS ((a, b), (a), ())` : phân cấp, cuộn từ phải sang trái |
| `CUBE (a, b)` | `GROUPING SETS ((a, b), (a), (b), ())` : mọi tổ hợp |

Ở dòng tổng, cột bị "cuộn" có giá trị NULL. Vấn đề: dữ liệu thật cũng có thể có NULL. Hàm `grouping(col)` trả `1` nếu cột đó bị cuộn trong dòng này, `0` nếu không. Hàm nhiều đối số `grouping(a, b)` trả một số nhị phân (0 = chi tiết, 1 = cuộn b, 2 = cuộn a, 3 = tổng chung).
```sql
SELECT CASE WHEN grouping(country) = 1 THEN '(tất cả)' ELSE country END AS country,
       count(*)
FROM users GROUP BY ROLLUP (country) ORDER BY grouping(country), country;
```
- `coalesce(col, '(tổng)')` là cách sai kinh điển: gán nhãn "tổng" cho cả dòng NULL thật.
- Sắp xếp theo `grouping(…)` trước để dòng tổng nằm cuối nhóm của nó.
- `grouping()` chỉ dùng được trong truy vấn có `GROUP BY` (SELECT, HAVING, ORDER BY).
- Một biểu thức trong `GROUPING SETS` phải **khớp nguyên văn** với biểu thức trong `SELECT`/`grouping()`.

## 3. Pivot bằng FILTER
Biến giá trị của một cột thành nhiều cột:
```sql
SELECT date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') AS thang,
       count(*) AS n_orders,
       count(*) FILTER (WHERE status = 'delivered') AS delivered,
       count(*) FILTER (WHERE status = 'cancelled') AS cancelled
FROM orders GROUP BY 1 ORDER BY 1;
```
- Chạy một lần quét, không cần extension. Số cột phải biết trước.
- `sum(CASE WHEN … THEN 1 ELSE 0 END)` cho kết quả như nhau, dài hơn.
- Kiểm tra: tổng các cột con phải bằng cột tổng. Thiếu một nhóm "khác" là lỗi hay gặp.

## 4. crosstab (tablefunc)
```sql
SELECT * FROM crosstab(
  $$ SELECT hang, cot, gia_tri FROM … ORDER BY 1, 2 $$,   -- 3 cột: hàng, cột, giá trị; sắp theo hàng
  $$ VALUES (1), (2), (3) $$                              -- danh sách giá trị cột, theo thứ tự cột đầu ra
) AS ct(hang text, q1 numeric, q2 numeric, q3 numeric);   -- phải khai báo kiểu kết quả
```
- Luôn dùng dạng **2 tham số**. Dạng 1 tham số khi có ô thiếu sẽ dồn giá trị sang trái vào sai cột.
- Tên và số cột đầu ra bị cố định lúc viết câu lệnh. Cột động phải sinh SQL bằng code ngoài.
- Nếu số cột cố định và nhỏ, `FILTER` đơn giản hơn và không cần extension.

## Bẫy hay gặp
1. `coalesce(col, '(tổng)')` thay cho `grouping()`.
2. `CROSS JOIN LATERAL` làm rơi dòng bên trái không có kết quả.
3. `LIMIT` đặt ngoài LATERAL.
4. Pivot thiếu cột "khác" nên tổng các cột không khớp.
5. `crosstab` 1 tham số khi dữ liệu có ô trống.
6. Chia % trên tổng chung cho mọi dòng thay vì dòng cha.
7. LATERAL trên bảng trái hàng triệu dòng: mỗi dòng một lần chạy subquery.

## Postgres-specific
- `FILTER (WHERE …)` là chuẩn SQL nhưng MySQL không có; `crosstab` là extension riêng của Postgres.
- `LATERAL` tương đương `CROSS APPLY` / `OUTER APPLY` của SQL Server; Postgres viết `LEFT JOIN LATERAL … ON true` cho OUTER APPLY.
- Postgres chạy LATERAL dưới dạng Nested Loop; xem `loops=` trong `EXPLAIN ANALYZE` để biết subquery chạy bao nhiêu lần.
