# I06 · Text & regex

Đọc khoảng 9 phút. Ví dụ chạy trên `shop_s`.

## Mục tiêu: sau buổi này bạn làm được
- Chọn đúng giữa `LIKE`, `ILIKE`, `~`, `~*` và biết toán tử nào dùng được index.
- Dùng regex để **kiểm tra**, **trích** và **thay thế**: `~`, `substring(… FROM 'regex')`, `regexp_replace`, `regexp_matches`.
- **Tách** chuỗi thành nhiều dòng (`regexp_split_to_table`, `string_to_array` + `unnest`) và **gộp** lại (`string_agg`).
- Chuẩn hóa tiếng Việt: chữ hoa/thường, khoảng trắng, **bỏ dấu** bằng `unaccent`.

---

## 1. So khớp mẫu
| Toán tử | Ý nghĩa | Ví dụ |
|---|---|---|
| `LIKE` | mẫu đơn giản, phân biệt hoa thường: `%` = chuỗi bất kỳ, `_` = 1 ký tự | `name LIKE 'Tai nghe%'` |
| `ILIKE` | như LIKE, **không** phân biệt hoa thường | `name ILIKE '%tai nghe%'` |
| `~` / `~*` | regex POSIX, phân biệt / không phân biệt hoa thường | `phone ~ '^0\d{9}$'` |
| `!~` / `!~*` | phủ định | `email !~ '@'` |

- Regex **không tự neo**: `'\d{9}'` khớp mọi chuỗi **chứa** 9 số liền nhau. Muốn khớp cả chuỗi phải viết `^…$`.
- Muốn tìm chính ký tự `%` hay `_` trong LIKE: `LIKE '%\_%'` (mặc định `\` là ký tự escape).
- Ký hiệu regex hay dùng: `\d` số · `\D` không phải số · `\s` khoảng trắng · `\S` không phải khoảng trắng · `[A-Z]` · `{n}` · `{n,m}` · `+` · `*` · `?` · `(…)` nhóm bắt · `|` hoặc.

## 2. Trích và thay
```sql
SELECT substring('Ốp lưng Samsung C4CA' FROM '([0-9A-F]{4})$')     AS ma,       -- C4CA (lấy nhóm bắt đầu tiên)
       regexp_replace('+84 954-511-385', '\D', '', 'g')             AS so,       -- 84954511385 (cờ 'g' = thay TẤT CẢ)
       regexp_replace('+84 954511385', '\D', '')                    AS mot_lan,  -- 84 954511385 (không 'g' = chỉ lần đầu)
       (regexp_match('an.nguyen@gmail.com', '^([^@]+)@(.+)$'))[2]   AS domain,   -- gmail.com
       split_part('an.nguyen@gmail.com', '@', 1)                    AS local;    -- an.nguyen
```
- `regexp_replace(s, mẫu, thay, cờ)`: cờ `'g'` để thay mọi chỗ khớp, `'i'` để không phân biệt hoa thường. Trong chuỗi thay, `\1` tham chiếu nhóm bắt số 1.
- `regexp_match` trả về **mảng** các nhóm bắt của lần khớp đầu tiên. `regexp_matches(…, 'g')` trả về **nhiều dòng**, mỗi lần khớp một dòng.
- Postgres 15+ có thêm `regexp_count`, `regexp_instr`, `regexp_substr`.

## 3. Tách chuỗi thành dòng, gộp dòng thành chuỗi
```sql
-- tách: một từ khóa thành nhiều dòng
SELECT t FROM regexp_split_to_table('giày  chạy bộ', '\s+') AS t;           -- giày | chạy | bộ
SELECT unnest(string_to_array('a,b,c', ','));                             -- a | b | c

-- gộp: nhiều dòng thành một chuỗi, có thứ tự
SELECT order_id, string_agg(product_id::text, ', ' ORDER BY line_no)
FROM order_items WHERE order_id <= 2 GROUP BY order_id;
```
- Dùng hàm sinh nhiều dòng trong `FROM`: `FROM events, regexp_split_to_table(…) AS token`. Dấu phẩy ở đây là một LATERAL JOIN ngầm (I08).
- Tách bằng `'\s+'` (một hoặc nhiều khoảng trắng), đừng tách bằng `' '`: hai khoảng trắng liền nhau sẽ sinh ra từ rỗng.

## 4. Chuẩn hóa tiếng Việt
```sql
SELECT unaccent('Giày Chạy Bộ Đỏ'),                         -- Giay Chay Bo Do
       lower(unaccent(trim('  Áo THUN  '))),                -- ao thun
       initcap('nguyễn văn an');                             -- Nguyễn Văn An
```
- `unaccent` là extension (`CREATE EXTENSION unaccent`), đã cài sẵn trong `shop_*` và `lab`. Nó đổi `đ/Đ` thành `d/D`.
- `unaccent` được khai báo là STABLE, không phải IMMUTABLE, nên **không đưa thẳng vào index** được. Muốn index thì bọc trong một hàm IMMUTABLE tự viết (R11).
- So sánh "giống nhau" theo nghiệp vụ = so sánh **sau khi chuẩn hóa**: `lower(unaccent(trim(x)))`.

## 5. Collation (ngắn gọn)
Thứ tự sắp xếp chữ phụ thuộc collation của DB (ở đây `en_US.utf8`): chữ hoa/thường và chữ có dấu được xếp gần nhau, không theo mã byte. `ORDER BY name COLLATE "C"` sắp theo mã byte (nhanh, nhưng 'Z' đứng trước 'a'). Một B-tree index thường chỉ phục vụ `LIKE 'abc%'` khi dùng collation `C` hoặc operator class `text_pattern_ops`.

## 6. Hiệu năng
- `LIKE 'abc%'` (biết phần đầu): dùng được B-tree (với `text_pattern_ops` hoặc collation C).
- `LIKE '%abc%'`, `ILIKE`, regex: B-tree **không** giúp được. Cần index **trigram** `gin (cot gin_trgm_ops)` (P05, R11). Ngay cả khi có trigram, điều kiện khớp quá nhiều dòng vẫn chậm (ex10).

## Bẫy hay gặp
1. Regex thiếu `^$` → "chứa" thay vì "đúng bằng".
2. `regexp_replace` quên cờ `'g'` → chỉ thay chỗ khớp đầu tiên.
3. Gom nhóm trên chuỗi chưa chuẩn hóa (hoa/thường, dấu, khoảng trắng).
4. `split_part(full_name, ' ', 3)` giả định tên luôn có 3 từ.
5. `string_agg` không có `ORDER BY` → thứ tự thay đổi giữa các lần chạy.

## Postgres-specific
- `ILIKE`, `~`, `unaccent`, `pg_trgm`, `regexp_split_to_table` là đặc trưng của Postgres. MySQL dùng `REGEXP`/`RLIKE`, và collation mặc định không phân biệt hoa thường.
