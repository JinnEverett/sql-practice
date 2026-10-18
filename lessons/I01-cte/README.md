# I01 · CTE (`WITH`)

Đọc khoảng 8 phút. Ví dụ chạy trên `shop_s`.

## Mục tiêu: sau buổi này bạn làm được
- Chia một query dài thành các **bước có tên** bằng `WITH`, mỗi bước là một CTE.
- Dùng một CTE **nhiều lần**, và cho CTE sau dùng CTE trước.
- Viết **data-modifying CTE**: `DELETE/INSERT/UPDATE … RETURNING` trong `WITH`, gộp nhiều thao tác thành một câu lệnh nguyên tử.
- Biết khi nào CTE bị **materialize** và vì sao điều đó có thể làm query chậm đi hàng nghìn lần.

---

## 1. Cú pháp
```sql
WITH user_totals AS (                      -- bước 1: tổng chi tiêu mỗi khách
  SELECT user_id, sum(total_amount) AS total_spent
  FROM orders WHERE status = 'delivered'
  GROUP BY user_id
), stats AS (                              -- bước 2: dùng lại bước 1
  SELECT avg(total_spent) AS avg_spent FROM user_totals
)
SELECT u.user_id, u.total_spent
FROM user_totals u, stats s
WHERE u.total_spent > s.avg_spent * 3
ORDER BY u.total_spent DESC
LIMIT 3;
```
- Các CTE cách nhau bằng dấu phẩy, chỉ có **một** chữ `WITH`. Sau CTE cuối là câu lệnh chính.
- CTE chỉ sống trong **một câu lệnh**. Nó không phải bảng tạm, câu lệnh sau không thấy nó.
- CTE sau được dùng CTE trước, nhưng không dùng ngược lại được (trừ `WITH RECURSIVE`, học ở I02).
- Đặt tên CTE theo **ý nghĩa nghiệp vụ** (`first_orders`, `new_customers`), đừng đặt `t1`, `t2`.

## 2. CTE và subquery: chọn cái nào?
| | Subquery trong `FROM` | CTE |
|---|---|---|
| Đọc | lồng từ trong ra ngoài | đọc từ trên xuống, như các bước |
| Dùng lại | phải viết lặp | đặt tên một lần, dùng nhiều lần |
| Hiệu năng (PG ≥ 12) | như nhau nếu CTE chỉ dùng một lần | |

CTE không làm query nhanh hơn. Lợi ích của nó là **dễ đọc, dễ kiểm tra từng bước**: tạm thay câu chính bằng `SELECT * FROM buoc_2` để xem kết quả giữa chừng.

## 3. Mẫu "gom trước, nối sau" để tránh fan-out
```sql
WITH views AS (SELECT (properties->>'product_id')::bigint AS product_id, count(*) AS n_views
               FROM events WHERE event_type = 'product_view' GROUP BY 1),
     carts AS (SELECT (properties->>'product_id')::bigint AS product_id, count(*) AS n_carts
               FROM events WHERE event_type = 'add_to_cart'  GROUP BY 1)
SELECT v.product_id, v.n_views, coalesce(c.n_carts, 0) AS n_carts
FROM views v LEFT JOIN carts c USING (product_id)
ORDER BY v.n_views DESC LIMIT 3;
```
Mỗi CTE đã gom về **1 dòng/sản phẩm** trước khi JOIN, nên không bị nhân dòng (bạn đã gặp lỗi này ở F05). `properties->>'product_id'` lấy một trường trong jsonb dưới dạng text, I07 sẽ học kỹ.

## 4. Data-modifying CTE
```sql
-- chuyển đơn sang bảng lưu trữ: xóa và chép trong MỘT câu lệnh
WITH moved AS (
  DELETE FROM i01.orders WHERE status = 'cancelled' AND created_at < '2026-03-01 00:00+07'
  RETURNING id, user_id, status, created_at, total
)
INSERT INTO i01.orders_archive (id, user_id, status, created_at, total)
SELECT * FROM moved;

-- chèn cha rồi dùng id vừa sinh để chèn con
WITH o AS (INSERT INTO i01.orders (user_id, status, created_at, total)
           VALUES (9, 'pending', now(), 0) RETURNING id)
INSERT INTO i01.order_items (order_id, line_no, product_id, quantity, unit_price)
SELECT o.id, 1, 101, 1, 50000 FROM o;
```
- `RETURNING` biến lệnh ghi thành một "bảng" để bước sau đọc.
- Cả câu là **một câu lệnh**, nên nguyên tử: hoặc mọi bước thành công, hoặc không bước nào được ghi.
- Mọi bước nhìn **cùng một snapshot**: câu chính **không** thấy thay đổi của CTE khi đọc thẳng bảng gốc, chỉ thấy qua `RETURNING`. Đừng viết hai CTE cùng sửa một dòng.

## 5. ⚠️ Materialize: khi CTE thành "hàng rào"
Từ Postgres 12, CTE **dùng đúng một lần** được planner gộp (inline) vào query chính, giống subquery. Nhờ vậy điều kiện ngoài được đẩy xuống và index vẫn dùng được. CTE bị **materialize** (chạy trọn vẹn trước, kết quả lưu tạm, rồi mới lọc) khi:
- được tham chiếu **≥ 2 lần**;
- là data-modifying, recursive, hoặc chứa hàm volatile;
- bạn viết `WITH x AS MATERIALIZED (…)`.

```sql
EXPLAIN (COSTS OFF) WITH o AS MATERIALIZED (SELECT * FROM orders) SELECT * FROM o WHERE id = 5000;
--  CTE Scan on o  Filter: (id = 5000)      ← đọc HẾT orders rồi mới lọc
--    CTE o -> Seq Scan on orders
EXPLAIN (COSTS OFF) WITH o AS (SELECT * FROM orders) SELECT * FROM o WHERE id = 5000;
--  Index Scan using orders_pkey on orders  ← điều kiện được đẩy xuống
```
Bài ex10 đo xem chênh lệch này lớn cỡ nào ở 10 triệu dòng.

## Bẫy hay gặp
1. Nghĩ CTE là "biến được tính một lần cho nhanh". Thực ra nó có thể chạy lại (inline) hoặc chặn tối ưu (materialize). Xem `EXPLAIN` để biết.
2. Lọc ở câu chính mà quên lọc ở CTE gốc, trong khi CTE đó được dùng hai lần. Hai chỗ dùng sẽ thấy tập khác nhau.
3. CTE chỉ lấy đúng khoảng cần in, nên phép so sánh "tháng trước" của tháng đầu tiên ra NULL (ex04).
4. Data-modifying CTE: tưởng câu chính đọc bảng gốc sẽ thấy dòng vừa xóa hoặc chèn. Không: phải đọc qua `RETURNING`.

## Postgres-specific
- MySQL có CTE từ 8.0 nhưng **không có** data-modifying CTE.
- Postgres ≤ 11 **luôn** materialize CTE. Tài liệu cũ hay khuyên "tránh CTE vì chậm", lời khuyên này đã lỗi thời từ PG 12.
