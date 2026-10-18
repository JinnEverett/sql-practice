# F05 · JOINs

Đọc khoảng 10 phút. Mọi ví dụ chạy trên `shop_s`.

## Mục tiêu: sau buổi này bạn làm được
- Ghép 2–3 bảng theo khóa ngoại bằng `JOIN … ON`.
- Chọn đúng giữa `INNER JOIN` và `LEFT JOIN`, và tìm các dòng "không có cặp" (anti join).
- Biết điều kiện nào đặt ở `ON`, điều kiện nào đặt ở `WHERE` khi dùng `LEFT JOIN`.
- Ghép một bảng với chính nó (self join).
- Nhận ra **fan-out** (nhân dòng) và tránh nó bằng cách gộp trước rồi mới JOIN.

---

## 0. Trước khi JOIN: mỗi dòng của bảng là một cái gì?
| Bảng | 1 dòng là | Nối với |
|---|---|---|
| `users` | 1 khách | |
| `orders` | 1 đơn | `orders.user_id → users.id` |
| `order_items` | 1 dòng hàng trong đơn | `order_id → orders.id`, `product_id → products.id` |
| `payments` | 1 lần thanh toán | `order_id → orders.id` |
| `products` | 1 sản phẩm | `category_id → categories.id` |
| `categories` | 1 danh mục | `parent_id → categories.id` (chính nó) |

Câu hỏi này quyết định cả bài: nó cho biết JOIN xong thì **mỗi dòng kết quả là cái gì**, và có bị nhân dòng không.

## 1. `INNER JOIN`: chỉ giữ các cặp khớp nhau
```sql
SELECT o.id AS order_id, u.full_name, o.total_amount
FROM orders o
JOIN users u ON u.id = o.user_id        -- JOIN = INNER JOIN
WHERE o.id <= 3;
```
- `o`, `u` là **alias bảng**. Khi có từ 2 bảng trở lên, luôn ghi rõ `bảng.cột` (`o.id`, `u.id`), vì cả hai bảng đều có cột `id`.
- Nối 3 bảng: thêm từng `JOIN … ON` một, mỗi lần nối theo đúng một khóa ngoại.
```sql
FROM order_items oi
JOIN products p   ON p.id = oi.product_id
JOIN categories c ON c.id = p.category_id
```

## 2. `LEFT JOIN`: giữ mọi dòng của bảng bên trái
Dòng bên trái không có cặp vẫn được giữ, và **mọi cột của bảng bên phải là NULL**.
```sql
SELECT count(*) FROM users u JOIN      orders o ON o.user_id = u.id;   -- 10000
SELECT count(*) FROM users u LEFT JOIN orders o ON o.user_id = u.id;   -- 10010: thêm 10 khách chưa mua lần nào
```

**Anti join** ("có bên A nhưng không có bên B"): `LEFT JOIN` rồi giữ các dòng mà bên phải là NULL.
```sql
SELECT u.id FROM users u LEFT JOIN orders o ON o.user_id = u.id
WHERE o.id IS NULL;                       -- kiểm tra cột NOT NULL của bên phải, thường là khóa chính
```

**Đếm sau `LEFT JOIN`:** dùng `count(<cột của bảng bên phải>)`, đừng dùng `count(*)`.
```
 user | count(*) | count(o.id)
    1 |     1007 |        1007
  467 |        1 |           0     ← khách chưa mua: vẫn có 1 dòng (toàn NULL), count(*) đếm nó
```

## 3. `ON` hay `WHERE`? (chỉ quan trọng với `LEFT JOIN`)
- `ON`: điều kiện để **ghép cặp**. Không khớp thì dòng bên trái vẫn được giữ, bên phải thành NULL.
- `WHERE`: chạy **sau** JOIN, lọc trên kết quả. Nếu đặt điều kiện về **bảng bên phải** ở `WHERE`, các dòng NULL bị loại (`NULL >= …` ra NULL, nhớ F03), nên `LEFT JOIN` âm thầm biến thành `INNER JOIN`.

```sql
-- Đếm đơn tháng 9 của mỗi khách, KỂ CẢ khách 0 đơn
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
                  AND o.created_at >= '2026-09-01 00:00+07'   -- điều kiện của bảng phải → ON
WHERE u.country = 'JP'                                        -- điều kiện của bảng trái → WHERE
```
Với `INNER JOIN`, đặt ở `ON` hay `WHERE` cho cùng kết quả.

## 4. Self join: ghép bảng với chính nó
Đặt cho cùng một bảng 2 alias khác nhau, rồi coi như 2 bảng:
```sql
SELECT c.name AS child, p.name AS parent
FROM categories c
LEFT JOIN categories p ON p.id = c.parent_id;   -- LEFT để giữ danh mục gốc (parent_id NULL)
```
Tìm **cặp** trong cùng một bảng (ví dụ 2 dòng trùng nhau): dùng `a.id < b.id` để mỗi cặp chỉ xuất hiện một lần, và không ghép một dòng với chính nó.

## 5. Fan-out: JOIN làm nhân dòng
Nối `orders` (1) với `order_items` (nhiều) thì mỗi đơn lặp lại **theo số dòng hàng**. Mọi phép `sum`/`count` trên cột của `orders` sau đó đều bị nhân lên:
```sql
SELECT sum(o.total_amount) FROM orders o JOIN order_items oi ON oi.order_id = o.id
WHERE o.id = 1;      -- 8796000 = 4 × 2199000, vì đơn 1 có 4 dòng hàng
```
Nặng hơn: nối **hai** bảng "nhiều" cùng lúc (`order_items` và `payments`) thì số dòng = items × payments.

Cách tránh:
1. Chỉ cần **danh sách** không trùng: `SELECT DISTINCT …` hoặc `GROUP BY` theo khóa chính.
2. Cần **cộng số** từ bảng "nhiều": **gộp trước, JOIN sau**. Gộp bảng con về 1 dòng/đơn trong một subquery ở `FROM` (derived table), rồi mới JOIN:
```sql
SELECT o.id, o.total_amount, i.n_lines
FROM orders o
JOIN (SELECT order_id, count(*) AS n_lines
      FROM order_items GROUP BY order_id) i ON i.order_id = o.id   -- i: đúng 1 dòng mỗi đơn
WHERE o.id <= 3;
```
Đừng "chữa" bằng `sum(DISTINCT amount)`: hai lần thanh toán cùng số tiền sẽ chỉ được cộng một lần.

## 6. Các loại còn lại (biết để đọc hiểu)
| Loại | Ý nghĩa | Ghi chú |
|---|---|---|
| `RIGHT JOIN` | giữ mọi dòng bên phải | Hiếm dùng: đảo thứ tự bảng rồi dùng `LEFT JOIN` cho dễ đọc |
| `FULL JOIN` | giữ mọi dòng cả hai bên | Dùng khi đối soát 2 nguồn: dòng chỉ có bên A, chỉ có bên B, có cả hai |
| `CROSS JOIN` | mọi tổ hợp, không có `ON` | 4 method × 3 status = 12 dòng. Hay dùng để tạo "khung" báo cáo đủ mọi ô |
| `JOIN … USING (col)` | viết tắt của `ON a.col = b.col` | Chỉ dùng được khi hai cột cùng tên |

---

## Bẫy hay gặp

| # | Sai | Đúng | Vì sao |
|---|---|---|---|
| 1 | `count(*)` sau `LEFT JOIN` | `count(o.id)` | Dòng không có cặp vẫn là 1 dòng, nên `count(*)` ra 1 thay vì 0 |
| 2 | `LEFT JOIN orders o … WHERE o.created_at >= …` | đưa điều kiện của `o` vào `ON` | Điều kiện trên bảng phải ở `WHERE` loại các dòng NULL, `LEFT` thành `INNER` |
| 3 | `sum(o.total_amount)` sau khi JOIN `order_items` | gộp trước, JOIN sau | Fan-out: mỗi đơn bị cộng N lần |
| 4 | `SELECT o.id …` sau JOIN `order_items` để lấy danh sách đơn | `SELECT DISTINCT o.id …` | Đơn có nhiều dòng khớp xuất hiện nhiều lần |
| 5 | Self join `ON a.email = b.email` | thêm `AND a.id < b.id` | Thiếu thì mỗi dòng tự ghép với chính nó, và mỗi cặp xuất hiện 2 lần (A,B) và (B,A) |

## Postgres-specific
- Postgres không có cú pháp `(+)` của Oracle hay `*=` của SQL Server cũ. Luôn viết `LEFT JOIN … ON` theo chuẩn.
- Có `JOIN … USING` và `NATURAL JOIN`. **Tránh `NATURAL JOIN`**: nó tự ghép theo mọi cột trùng tên (cả `id`, `created_at`), rất dễ ra kết quả sai mà không báo lỗi.
- Postgres tự chọn thuật toán JOIN (Nested Loop, Hash Join, Merge Join) và thứ tự JOIN. Bạn sẽ đọc các thuật toán này trong `EXPLAIN` ở Tier P.
