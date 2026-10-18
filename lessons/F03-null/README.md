# F03 · NULL

Đọc khoảng 10 phút. Các ví dụ không ghi tên bảng chạy được trên mọi DB. Ví dụ có bảng thì chạy trên `shop_s`.

## Mục tiêu: sau buổi này bạn làm được
- Đoán trước kết quả của mọi biểu thức có NULL (`=`, `<>`, `AND`, `OR`, `NOT`, `IN`, `NOT IN`).
- Lọc đúng các dòng "khác X", có tính cả những dòng chưa có giá trị.
- Thay NULL bằng giá trị hiển thị (`COALESCE`), đổi giá trị rác thành NULL (`NULLIF`), và tránh lỗi chia cho 0.
- Biết `COUNT`, `SUM` và `AVG` xử lý NULL thế nào, và chọn đúng giữa "bỏ qua NULL" với "coi NULL là 0".
- Đặt NULL lên đầu hoặc xuống cuối khi sắp xếp.

---

## 1. NULL nghĩa là "không biết"
NULL không phải là 0, không phải chuỗi rỗng `''`, cũng không phải `false`. NULL nghĩa là **chưa biết giá trị**.
Vì vậy mọi phép so sánh với NULL đều ra NULL, tức là "không biết": hai thứ chưa biết thì không thể nói là bằng nhau.

```sql
SELECT NULL = NULL, NULL <> 1, NULL > 0, 1 + NULL, 'a' || NULL;
--       NULL        NULL       NULL      NULL      NULL
```

`WHERE` **chỉ giữ dòng có điều kiện là `true`**. Các dòng mà điều kiện ra `false` **hoặc NULL** đều bị loại.

```sql
-- users.city có 47 dòng NULL trong shop_s
SELECT count(*) FROM users WHERE city = 'Hà Nội';     -- 208
SELECT count(*) FROM users WHERE city <> 'Hà Nội';    -- 745, không phải 792: mất 47 dòng NULL
SELECT count(*) FROM users;                           -- 1000 = 208 + 745 + 47
```

## 2. Logic ba trị: `AND`, `OR`, `NOT`
Hãy coi NULL là "chưa biết đúng hay sai". Muốn biết kết quả, thử thay NULL lần lượt bằng `true` và `false`: nếu hai lần cho cùng kết quả thì đó là kết quả cuối, còn nếu khác nhau thì kết quả là NULL.

| A | B | A AND B | A OR B |
|---|---|---|---|
| true | NULL | NULL | **true** |
| false | NULL | **false** | NULL |
| NULL | NULL | NULL | NULL |

`NOT NULL` cũng ra NULL. Vì vậy `NOT (city = 'Hà Nội')` vẫn làm mất các dòng có city NULL.

## 3. Kiểm tra NULL: `IS NULL` và `IS DISTINCT FROM`
```sql
SELECT count(*) FROM users WHERE city IS NULL;        -- 47. Viết "city = NULL" sẽ luôn ra 0 dòng
```

`IS DISTINCT FROM` là phép "khác" **coi NULL là một giá trị**. Kết quả của nó luôn là `true` hoặc `false`, không bao giờ ra NULL:

| a | b | `a <> b` | `a IS DISTINCT FROM b` |
|---|---|---|---|
| 1 | 2 | true | true |
| 1 | 1 | false | false |
| 1 | NULL | **NULL** | **true** |
| NULL | NULL | **NULL** | **false** |

```sql
SELECT count(*) FROM users WHERE city IS DISTINCT FROM 'Hà Nội';   -- 792 (có tính 47 dòng NULL)
-- Cách viết tương đương: WHERE city <> 'Hà Nội' OR city IS NULL
```
Phép ngược lại là `IS NOT DISTINCT FROM`, nghĩa là "bằng nhau, coi NULL = NULL".

## 4. `COALESCE` và `NULLIF`
- `COALESCE(a, b, c, …)` trả về **giá trị đầu tiên khác NULL**. Hay dùng để hiển thị giá trị mặc định.
- `NULLIF(a, b)` trả về NULL nếu `a = b`, ngược lại trả về `a`. Hay dùng để **biến giá trị rác thành NULL**.

```sql
SELECT id, coalesce(city, 'Chưa cập nhật') AS city FROM users WHERE id <= 5;
SELECT nullif('', ''), nullif('Huế', '');          -- NULL, 'Huế'
SELECT 100 / nullif(0, 0);                          -- NULL thay vì ERROR: division by zero
```
Hai hàm này hay đi cùng nhau. Ví dụ `coalesce(nullif(x, ''), 'mặc định')` nghĩa là "rỗng hoặc NULL thì dùng giá trị mặc định".

## 5. NULL trong `IN` và `NOT IN`
`x IN (a, b)` thực chất là `x = a OR x = b`. Còn `x NOT IN (a, b)` là `x <> a AND x <> b`.

```sql
SELECT 1 IN (1, NULL);        -- true   (true OR NULL = true)
SELECT 3 IN (1, NULL);        -- NULL   (false OR NULL = NULL)
SELECT 3 NOT IN (1, NULL);    -- NULL   (true AND NULL = NULL)  → WHERE loại MỌI dòng
```
Chỉ cần danh sách có **một** NULL là `NOT IN` không bao giờ ra `true`. Bẫy này sẽ quay lại ở F06, khi danh sách là một subquery.

## 6. NULL trong aggregate
Hàm aggregate gộp nhiều dòng thành một giá trị. F04 sẽ học kỹ, còn ở đây chỉ cần biết cách các hàm này xử lý NULL:

| Hàm | Xử lý NULL |
|---|---|
| `count(*)` | Đếm **mọi dòng** |
| `count(col)` | Chỉ đếm dòng có `col` **khác NULL** |
| `sum(col)`, `avg(col)`, `min`, `max` | **Bỏ qua** NULL. Nếu không còn dòng nào thì trả về NULL (riêng `sum` cũng trả NULL, không phải 0) |

```sql
SELECT count(*), count(city), count(*) - count(city) AS null_city FROM users;   -- 1000, 953, 47
```
`avg(col)` = tổng của các giá trị khác NULL / **số giá trị khác NULL**. Còn `avg(coalesce(col, 0))` chia cho **mọi dòng**. Hai cách này trả lời hai câu hỏi khác nhau, nên phải chọn theo nghĩa nghiệp vụ.

Lưu ý: `count(...)` trả về `bigint`. Phép `count(a) / count(*)` là chia số nguyên (xem F02).

## 7. NULL khi sắp xếp
Postgres coi NULL **lớn hơn** mọi giá trị. Vì vậy `ASC` xếp NULL **xuống cuối**, còn `DESC` đưa NULL **lên đầu**.

```sql
SELECT id, birth_date FROM users ORDER BY birth_date DESC LIMIT 3;               -- 3 dòng NULL!
SELECT id, birth_date FROM users ORDER BY birth_date DESC NULLS LAST LIMIT 3;    -- người trẻ nhất
```

---

## Bẫy hay gặp

| # | Sai | Đúng | Vì sao |
|---|---|---|---|
| 1 | `WHERE city = NULL` | `WHERE city IS NULL` | `= NULL` luôn ra NULL, nên ra 0 dòng |
| 2 | `WHERE brand <> 'Sony'` (khi muốn giữ cả brand chưa rõ) | `WHERE brand IS DISTINCT FROM 'Sony'` | `NULL <> 'Sony'` ra NULL, dòng bị loại |
| 3 | `ORDER BY birth_date DESC LIMIT 10` | `… DESC NULLS LAST …` | `DESC` đưa NULL lên đầu |
| 4 | `clicks / impressions` | `clicks * 100.0 / nullif(impressions, 0)` | Lỗi chia cho 0, và chia số nguyên |
| 5 | `WHERE old_phone <> new_phone` (để phát hiện thay đổi) | `old_phone IS DISTINCT FROM new_phone` | NULL → số mới cũng là thay đổi, nhưng `<>` bỏ sót |

## Postgres-specific
- **Oracle** coi `''` là NULL. **Postgres thì không**: `''` là một chuỗi hợp lệ có độ dài 0. Dữ liệu import có thể chứa cả `''` lẫn NULL.
- `IS DISTINCT FROM` là chuẩn SQL nhưng **MySQL không có**. MySQL dùng toán tử `<=>`, tương đương `IS NOT DISTINCT FROM`.
- `NULLS FIRST` / `NULLS LAST` cũng không có trong MySQL. Còn SQL Server mặc định coi NULL **nhỏ nhất**, ngược với Postgres.
