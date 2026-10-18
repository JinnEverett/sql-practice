# F06 · Subqueries

Đọc khoảng 10 phút. Mọi ví dụ chạy trên `shop_s`.

## Mục tiêu: sau buổi này bạn làm được
- Dùng **scalar subquery** (trả về 1 giá trị) trong `WHERE` và `SELECT`.
- Kiểm tra "có / không có" bằng `IN`, `EXISTS`, `NOT EXISTS`, và biết vì sao **`NOT IN` nguy hiểm**.
- Viết **correlated subquery** (subquery tham chiếu dòng bên ngoài).
- Dùng **derived table** (subquery ở `FROM`) để tổng hợp hai tầng, ví dụ "trung bình của các tổng".
- Chọn giữa subquery và JOIN theo **ý đồ** của câu hỏi.

---

## 1. Subquery là gì
Là một câu `SELECT` đặt trong ngoặc, nằm bên trong một câu khác. Có 3 vị trí hay gặp:

| Vị trí | Subquery trả về | Ví dụ |
|---|---|---|
| `WHERE … > (…)` / trong `SELECT` | **1 giá trị** (scalar) | so với trung bình |
| `WHERE … IN (…)` / `EXISTS (…)` | **một tập** dòng | "có mua", "không mua" |
| `FROM (…) AS t` | **một bảng** (derived table) | gộp trước, dùng sau |

## 2. Scalar subquery: đúng 1 cột, tối đa 1 dòng
```sql
SELECT count(*) FROM orders
WHERE total_amount > (SELECT avg(total_amount) FROM orders);   -- 2413 đơn trên trung bình 6832435.60
```
- Subquery trả về **0 dòng** thì giá trị là **NULL**, không báo lỗi:
  ```sql
  SELECT (SELECT id FROM users WHERE country = 'XX');   -- NULL
  ```
- Subquery trả về **nhiều hơn 1 dòng** thì báo lỗi lúc chạy:
  ```sql
  SELECT (SELECT id FROM users WHERE country = 'JP');
  -- ERROR: more than one row returned by a subquery used as an expression
  ```
- Không thể viết `WHERE total_amount > avg(total_amount)`, vì `WHERE` chạy **trước** khi tổng hợp (nhớ F04). Phải tính trung bình riêng trong một subquery.

## 3. `IN`: "giá trị nằm trong tập"
```sql
SELECT id, full_name FROM users
WHERE id IN (SELECT user_id FROM orders WHERE status = 'refunded');
```
- `IN` **không nhân dòng**: khách có 5 đơn refunded vẫn chỉ xuất hiện 1 lần. Nếu viết bằng JOIN thì phải thêm `DISTINCT` (F05 ex08).
- Subquery trong `IN` phải trả về **đúng 1 cột**.

## 4. `EXISTS`: "có ít nhất một dòng thỏa"
```sql
SELECT count(*) FROM users u
WHERE EXISTS (SELECT 1 FROM orders o
              WHERE o.user_id = u.id AND o.status = 'refunded');   -- 242 khách
-- JOIN thẳng sẽ ra 379: số ĐƠN refunded, không phải số KHÁCH
```
- `EXISTS` chỉ quan tâm subquery **có dòng hay không**, không quan tâm giá trị. Vì vậy người ta viết `SELECT 1`.
- Postgres **dừng ngay khi gặp dòng khớp đầu tiên**. Đây là **semi join**.
- `NOT EXISTS` là **anti join**: giữ dòng khi subquery không có dòng nào. Đây là cách viết anti join rõ ý nhất (so với `LEFT JOIN … IS NULL` ở F05).

## 5. Correlated subquery: subquery "nhìn ra ngoài"
Subquery ở mục 4 dùng `u.id` của câu bên ngoài, nên được gọi là **tương quan** (correlated). Về mặt ý nghĩa, nó được tính lại **cho từng dòng** bên ngoài.
```sql
SELECT o.id, o.total_amount,
       (SELECT count(*) FROM order_items oi WHERE oi.order_id = o.id) AS n_lines
FROM orders o WHERE o.id <= 3;
--  1 | 2199000.00 | 4
--  2 | 3152000.00 | 4
--  3 |  412000.00 | 1
```
- Correlated scalar subquery là một cách **khác** để tránh fan-out: mỗi dòng ngoài nhận đúng 1 giá trị.
- Cẩn thận: `count(*)` trên 0 dòng ra **0**, nhưng `sum/avg/max` trên 0 dòng ra **NULL** (F03, F04).

## 6. Derived table: tổng hợp hai tầng
"Trung bình **mỗi khách** đặt bao nhiêu đơn?" Đây là **trung bình của các count**, tức là phải tổng hợp hai lần:
```sql
SELECT round(avg(n), 2)
FROM (SELECT user_id, count(*) AS n FROM orders GROUP BY user_id) t;   -- 10.10
```
- Derived table **bắt buộc có alias** (`t`).
- Câu hỏi mẫu số: kết quả trên chỉ tính các khách **có ít nhất 1 đơn**. Nếu chia cho mọi khách thì ra `10.00`. Hai con số trả lời hai câu hỏi khác nhau, nên phải đọc đề để biết cần cái nào.
- Muốn lọc theo một cột tính ra (ví dụ alias `total_paid`), cũng bọc cả câu vào derived table, rồi mới `WHERE` ở tầng ngoài. Lý do là alias trong `SELECT` không dùng được ở `WHERE` cùng tầng (F01).

## 7. ⚠️ `NOT IN` gặp NULL
Bạn đã thấy ở warm-up: `3 NOT IN (1, 2, NULL)` được khai triển thành `3<>1 AND 3<>2 AND 3<>NULL`, tức là `TRUE AND TRUE AND NULL` = NULL. Kết quả là **không trả về dòng nào**.
```sql
SELECT 'có' WHERE 3 NOT IN (SELECT x FROM (VALUES (1), (2), (NULL)) v(x));   -- 0 dòng
SELECT 'có' WHERE NOT EXISTS (SELECT 1 FROM (VALUES (1), (2), (NULL)) v(x)
                              WHERE v.x = 3);                                -- 1 dòng
```
- Chỉ cần subquery có **một** giá trị NULL là toàn bộ `NOT IN` ra rỗng, **không báo lỗi gì**.
- `IN` (không có `NOT`) thì an toàn: `3 IN (3, NULL)` là `TRUE OR NULL` = TRUE.
- **Quy tắc:** muốn kiểm tra "không có" thì dùng `NOT EXISTS`. Nếu buộc phải dùng `NOT IN`, phải chắc chắn cột trong subquery là `NOT NULL`, hoặc tự lọc bỏ NULL. Ngoài lỗi đúng/sai, `NOT IN` còn có vấn đề hiệu năng: xem bonus.

## 8. Subquery hay JOIN?
| Câu hỏi | Nên dùng | Vì sao |
|---|---|---|
| Cần **cột** từ bảng kia | `JOIN` | Subquery ở `WHERE` không đưa cột ra ngoài được |
| "Có ít nhất một…" | `EXISTS` / `IN` | Không nhân dòng, dừng sớm |
| "Không có…" | `NOT EXISTS` | Đúng cả khi có NULL, planner nhận ra anti join |
| So với **1 con số** tổng hợp | scalar subquery | |
| Tổng hợp **hai tầng** | derived table | |

Postgres thường tự viết lại `IN`/`EXISTS` thành semi join và `NOT EXISTS` thành anti join, nên về tốc độ thì chúng ngang JOIN. `NOT IN` là **ngoại lệ**: planner không đổi được nó thành anti join.

---

## Bẫy hay gặp

| # | Sai | Đúng | Vì sao |
|---|---|---|---|
| 1 | `WHERE id NOT IN (SELECT col_co_null …)` | `NOT EXISTS (… WHERE col = id)` | Một NULL làm cả kết quả rỗng |
| 2 | `WHERE price > avg(price)` | `WHERE price > (SELECT avg(price) …)` | Hàm tổng hợp không dùng được trong `WHERE` |
| 3 | Subquery không lọc giống câu ngoài: `… is_active … > (SELECT avg(price) FROM products)` | lặp lại `WHERE is_active` bên trong | Subquery là một câu **độc lập**, nó không tự kế thừa điều kiện của câu ngoài |
| 4 | `(SELECT sum(amount) …)` cho đơn chưa có giao dịch | `coalesce((SELECT sum…), 0)` | Tổng trên 0 dòng là NULL, và `NULL <> x` cũng là NULL |
| 5 | Correlated subquery quên điều kiện tương quan: `(SELECT count(*) FROM order_items)` | `… WHERE oi.order_id = o.id` | Thiếu thì mọi dòng nhận cùng một số: tổng của cả bảng |

## Postgres-specific
- `= ANY (subquery)` tương đương `IN (subquery)`, còn `<> ALL (subquery)` tương đương `NOT IN` (và có cùng bẫy NULL).
- Correlated subquery ở `WHERE` dạng `EXISTS`/`IN` thường được planner **kéo phẳng** (pull up) thành semi/anti join. Correlated subquery ở `SELECT` thì thường chạy thật **cho từng dòng** (`SubPlan` trong `EXPLAIN`). Ở Tier P bạn sẽ đọc được hai node này.
- MySQL cũ (< 5.6) chạy subquery `IN` rất chậm, nên nhiều tài liệu cũ khuyên "luôn đổi subquery sang JOIN". Lời khuyên này không còn đúng với Postgres.
