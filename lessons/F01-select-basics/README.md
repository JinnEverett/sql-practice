# F01 · SELECT / WHERE / ORDER BY

Đọc khoảng 10 phút. Mọi ví dụ chạy được trên `shop_s`:

```bash
psql -h localhost -p 5433 -U postgres -d shop_s
```

## Mục tiêu: sau buổi này bạn làm được
- Lấy đúng các cột cần thiết, đặt alias, tính cột mới từ biểu thức.
- Lọc dòng bằng `WHERE` với `AND/OR/NOT`, `IN`, `BETWEEN`, `LIKE/ILIKE`, `IS NULL`, và biết thứ tự ưu tiên của chúng.
- Sắp xếp **xác định**: nhiều cột, có tie-break, kết quả giống nhau qua mọi lần chạy.
- Lấy top-N và phân trang bằng `LIMIT/OFFSET`.
- Giải thích được **thứ tự thực thi logic** của một câu `SELECT`, và dùng nó để biết vì sao một số query bị lỗi.

---

## 1. SELECT: chọn cột, biểu thức, alias

```sql
SELECT id, name, price,
       price / 25000          AS price_usd,     -- cột tính toán + alias
       price * 0.9 AS "Giá sau giảm"            -- alias có dấu cách/dấu: dùng ngoặc kép
FROM products
LIMIT 3;
```
- `AS` có thể bỏ (`price / 25000 price_usd`), nhưng nên viết rõ cho dễ đọc.
- **Nháy đơn `'...'` là chuỗi, nháy kép `"..."` là tên** (cột, bảng, alias). Viết `WHERE status = "paid"` sẽ lỗi `column "paid" does not exist`.
- Tránh dùng `SELECT *` trong code thật: tốn I/O, và query âm thầm thay đổi khi bảng thêm cột. Chỉ nên dùng khi khám phá dữ liệu.

## 2. WHERE: lọc dòng

| Toán tử | Ví dụ |
|---|---|
| So sánh | `price >= 1000000`, `status <> 'cancelled'` |
| Kết hợp | `AND`, `OR`, `NOT` |
| Tập giá trị | `status IN ('paid', 'shipped')` |
| Khoảng (gồm cả 2 đầu) | `price BETWEEN 100000 AND 500000` |
| Mẫu chuỗi | `name LIKE 'Áo%'` (phân biệt hoa/thường), `name ILIKE '%sony%'` (không phân biệt). `%` = chuỗi bất kỳ, `_` = đúng 1 ký tự |
| Rỗng | `deleted_at IS NULL`, `phone IS NOT NULL` |

```sql
SELECT id, status, total_amount
FROM orders
WHERE status IN ('paid', 'shipped') AND total_amount >= 10000000;
```

**So sánh với thời gian.** `created_at` có kiểu `timestamptz`, server để timezone UTC. Literal `'2025-01-01'` được hiểu là `2025-01-01 00:00:00` UTC. Chuyện giờ Việt Nam sẽ học ở F02/I05; buổi này mọi mốc thời gian đều tính theo **UTC**.

## 3. ORDER BY: sắp xếp

```sql
SELECT id, name, brand, price
FROM products
ORDER BY brand ASC, price DESC, id;   -- brand A→Z; cùng brand thì giá giảm dần; cùng giá thì id tăng
```
- Mặc định là `ASC`. `DESC` chỉ áp dụng cho **cột đứng ngay trước nó**: `ORDER BY a, b DESC` nghĩa là `a ASC, b DESC`.
- **Không có `ORDER BY` thì thứ tự không được đảm bảo**, dù lần nào chạy thử cũng có vẻ "đúng thứ tự id".
- **Tie-break:** nếu cột sắp xếp có giá trị trùng thì thêm một cột duy nhất (thường là `id`) vào cuối. Có vậy thứ tự mới xác định.
- Postgres: `NULL` được coi là **lớn nhất**, nên nằm cuối khi `ASC` và đầu khi `DESC`. Đổi bằng `NULLS FIRST / NULLS LAST` (sẽ học kỹ ở F03).

## 4. LIMIT / OFFSET: top-N và phân trang

```sql
-- 5 đơn mới nhất của user 1, trang 2 (bỏ qua 5 đơn đầu)
SELECT id, created_at, total_amount
FROM orders
WHERE user_id = 1
ORDER BY created_at DESC, id DESC
LIMIT 5 OFFSET 5;
```
- Trang `p` (bắt đầu từ 1) với `k` dòng mỗi trang: `LIMIT k OFFSET (p-1)*k`.
- `LIMIT` không có `ORDER BY` nghĩa là "lấy k dòng bất kỳ".
- Cú pháp chuẩn SQL tương đương: `OFFSET 5 ROWS FETCH FIRST 5 ROWS ONLY`.
- `OFFSET` lớn thì chậm, vì Postgres vẫn phải đọc rồi bỏ đi các dòng phía trước. Cách thay thế (keyset pagination) học ở R02.

## 5. DISTINCT: bỏ dòng trùng

```sql
SELECT DISTINCT status FROM orders ORDER BY status;          -- 6 dòng
SELECT DISTINCT country, city FROM users ORDER BY 1, 2;      -- trùng theo CẢ CẶP (country, city)
```
- `DISTINCT` áp dụng cho **cả dòng** gồm mọi cột trong `SELECT`, không phải chỉ cột đứng ngay sau nó.
- Riêng Postgres có `DISTINCT ON (cột)`: lấy 1 dòng đầu tiên cho mỗi nhóm. Cú pháp này sẽ dùng nhiều ở F06/I03, biết qua là đủ:
  ```sql
  SELECT DISTINCT ON (user_id) user_id, id, created_at
  FROM orders ORDER BY user_id, created_at DESC;   -- đơn mới nhất của mỗi user
  ```

## 6. Thứ tự thực thi logic

Thứ tự **viết** khác thứ tự **thực thi** (thực thi ở mức logic; planner có thể tối ưu khác đi, nhưng kết quả luôn như thể chạy theo thứ tự này):

```
viết:      SELECT → FROM → WHERE → GROUP BY → HAVING → ORDER BY → LIMIT
thực thi:  FROM → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT/OFFSET
```

Hệ quả:
- `WHERE` chạy **trước** `SELECT`, nên **không dùng được alias** đặt trong `SELECT`.
- `ORDER BY` chạy **sau** `SELECT`, nên **dùng được alias**.
- `LIMIT` chạy cuối cùng: lọc trước, sắp xếp, rồi mới cắt.

```sql
SELECT id, price / 25000 AS price_usd
FROM products
WHERE price / 25000 > 100        -- lặp lại biểu thức, không viết được: WHERE price_usd > 100
ORDER BY price_usd DESC;         -- ORDER BY thì dùng alias được
```

---

## Bẫy hay gặp

**1. `AND` được ưu tiên hơn `OR`**
```sql
-- SAI: được hiểu là  status='cancelled' OR (status='refunded' AND total_amount >= 5000000)
WHERE status = 'cancelled' OR status = 'refunded' AND total_amount >= 5000000
-- ĐÚNG
WHERE (status = 'cancelled' OR status = 'refunded') AND total_amount >= 5000000
WHERE status IN ('cancelled', 'refunded') AND total_amount >= 5000000
```

**2. `BETWEEN` với timestamp**
```sql
-- SAI: '2025-12-31' là 2025-12-31 00:00:00, nên mất gần trọn ngày 31/12
WHERE created_at BETWEEN '2025-01-01' AND '2025-12-31'
-- ĐÚNG: khoảng nửa mở  [đầu, cuối)
WHERE created_at >= '2025-01-01' AND created_at < '2026-01-01'
```

**3. Dùng alias trong `WHERE`**: lỗi `column "price_usd" does not exist`. Xem mục 6.

**4. So sánh với NULL bằng `=`**
```sql
WHERE deleted_at = NULL     -- SAI: luôn ra 0 dòng (NULL = NULL không phải TRUE)
WHERE deleted_at IS NULL    -- ĐÚNG
```

**5. Phân trang không có tie-break**: nếu `ORDER BY created_at` có 2 dòng trùng giờ, một dòng có thể xuất hiện ở cả trang 1 lẫn trang 2, còn dòng kia biến mất. Luôn thêm `id` vào cuối `ORDER BY`.

## Postgres khác gì MySQL / SQL Server?
- Top-N: Postgres dùng `LIMIT n` (hoặc `FETCH FIRST`). SQL Server dùng `TOP n`.
- `ILIKE` chỉ có ở Postgres. MySQL so chuỗi mặc định không phân biệt hoa/thường; Postgres thì **có phân biệt**.
- Tên không bọc ngoặc kép bị chuyển thành chữ thường (`SELECT Name` tức là `name`). Bọc ngoặc kép thì giữ nguyên chữ hoa/thường. MySQL dùng backtick thay cho ngoặc kép.
- Chuỗi phải dùng nháy đơn. MySQL chấp nhận nháy kép cho chuỗi, Postgres thì không.
