# F02 · Data types

Đọc khoảng 10 phút. Ví dụ chạy được trên DB bất kỳ, trừ chỗ ghi rõ tên bảng.

## Mục tiêu: sau buổi này bạn làm được
- Chọn đúng kiểu cho **tiền**, **số đếm**, **thời điểm**, **mã định danh**, và giải thích vì sao.
- Biết trước kết quả của phép chia, phép làm tròn, và khi nào phép tính bị **tràn số**.
- Phân biệt `timestamp` với `timestamptz`, đổi qua lại giữa UTC và giờ Việt Nam mà không lệch giờ.
- Ép kiểu bằng `::` và biết khi nào ép kiểu cứu được dữ liệu "bẩn" của hệ thống cũ.

---

## 1. Số

| Kiểu | Phạm vi / độ chính xác | Dùng cho |
|---|---|---|
| `smallint` / `integer` / `bigint` | ±32 nghìn / **±2,1 tỷ** / ±9,2 × 10¹⁸ | đếm, id, số lượng |
| `numeric(p, s)` | chính xác tuyệt đối, `p` chữ số, `s` chữ số sau dấu phẩy | **tiền**, mọi thứ cần khớp từng đồng |
| `real` / `double precision` (`float8`) | xấp xỉ, ~15 chữ số có nghĩa | đo lường khoa học, tọa độ, điểm ML |

```sql
SELECT 0.1::float8 + 0.2::float8;   -- 0.30000000000000004  (float lưu nhị phân, 0.1 không biểu diễn chính xác được)
SELECT 0.1 + 0.2;                   -- 0.3                  (literal có dấu chấm mặc định là numeric)
```

**Phép chia số nguyên cắt bỏ phần thập phân** (cắt về phía 0, không làm tròn):
```sql
SELECT 7 / 2, -7 / 2, 7 % 3, 7 / 2.0, 7::numeric / 2;
--       3      -3      1    3.5000000000000000   3.5000000000000000
```

**Tràn số:** `integer` tối đa 2 147 483 647. Phép tính giữa hai `integer` cho kết quả `integer`, vượt quá là lỗi:
```sql
SELECT 2147483647 + 1;              -- ERROR: integer out of range
SELECT 2147483647::bigint + 1;      -- 2147483648
```
Kiểu của kết quả được quyết định **trước khi** tính, dựa trên kiểu của các toán hạng.

**Làm tròn:**
```sql
SELECT round(2.5::numeric), round(-2.5::numeric), round(2.5::float8), round(3.5::float8);
--             3                 -3                    2                   4
SELECT round(2.567, 2);             -- 2.57
SELECT round(2.567::float8, 2);     -- ERROR: function round(double precision, integer) does not exist
SELECT ceil(2.1), floor(2.9), trunc(2.9);   -- 3, 2, 2
```
- `numeric`: làm tròn **xa số 0** (2.5 → 3), đúng như cách làm tròn ở trường.
- `float8`: làm tròn **về số chẵn gần nhất** (banker's rounding: 2.5 → 2, 3.5 → 4).

**Tiền: dùng `numeric`**, hoặc `bigint` lưu theo đơn vị nhỏ nhất (đồng, xu). Không dùng `float`. Tránh luôn kiểu `money` của Postgres vì nó phụ thuộc cấu hình `lc_monetary`.

## 2. Chuỗi
- `text` và `varchar` **giống hệt nhau về hiệu năng** trong Postgres. `varchar(n)` chỉ thêm một ràng buộc độ dài.
- `char(n)` tự đệm khoảng trắng cho đủ `n` ký tự, và bỏ khoảng trắng cuối khi so sánh. Chỉ nên dùng cho mã có độ dài cố định thật sự, như `users.country char(2)`. Còn lại dùng `text`.

## 3. Boolean
Có 3 giá trị: `true`, `false`, `NULL`. Khi ép từ chuỗi sang, Postgres chấp nhận nhiều cách viết, không phân biệt hoa/thường và bỏ qua khoảng trắng hai đầu:
```sql
SELECT 't'::boolean, 'yes'::boolean, ' Y '::boolean, 'on'::boolean, '1'::boolean;   -- tất cả là true
SELECT 'False'::boolean, 'no'::boolean, 'off'::boolean, '0'::boolean;              -- tất cả là false
```
Lọc theo cột boolean thì viết thẳng `WHERE is_active` hoặc `WHERE NOT is_active`.

## 4. Thời gian ⏰ (phần quan trọng nhất)

| Kiểu | Lưu gì | Ví dụ |
|---|---|---|
| `date` | ngày, không có giờ | `2026-09-09` |
| `timestamp` | **giờ trên đồng hồ treo tường**, không biết đang ở múi giờ nào | `2026-09-09 08:00` |
| `timestamptz` | **một thời điểm tuyệt đối**. Lưu bên trong là UTC, khi hiển thị thì đổi sang `TimeZone` của session | `2026-09-09 01:00:00+00` |
| `interval` | khoảng thời gian | `interval '7 hours'`, `interval '1 month'` |

Dùng `timestamptz` cho mọi thời điểm "sự kiện đã xảy ra" (đặt hàng, thanh toán, đăng ký). Bảng `shop_*` đều dùng `timestamptz`.

**`AT TIME ZONE` đổi qua lại hai kiểu:**
```sql
-- timestamptz → timestamp: "lúc đó đồng hồ ở Việt Nam chỉ mấy giờ?"
SELECT timestamptz '2026-01-01 00:00+00' AT TIME ZONE 'Asia/Ho_Chi_Minh';   -- 2026-01-01 07:00:00

-- timestamp → timestamptz: "đồng hồ ở Việt Nam chỉ 07:00, vậy đó là thời điểm nào?"
SELECT timestamp '2026-01-01 07:00' AT TIME ZONE 'Asia/Ho_Chi_Minh';        -- 2026-01-01 00:00:00+00
```

**Viết literal thời gian an toàn:** dùng định dạng ISO `YYYY-MM-DD`, kèm múi giờ.
```sql
WHERE created_at >= '2026-09-09 00:00+07' AND created_at < '2026-09-10 00:00+07'   -- ngày 9/9 theo giờ VN
```

## 5. UUID
- 16 byte. Dạng text của nó dài 36 ký tự, nên lưu bằng `text` tốn hơn gấp đôi, và không được kiểm tra hợp lệ.
- `gen_random_uuid()` sinh UUID v4 (ngẫu nhiên). **Postgres 18** có thêm `uuidv7()`: phần đầu của UUID là thời gian, nên các giá trị sinh ra tăng dần. Index nhờ vậy chèn vào cuối thay vì rải khắp nơi, hiệu năng tốt hơn hẳn khi bảng lớn (sẽ đo ở P02).
- Khi nhận đầu vào, kiểu `uuid` chấp nhận chữ hoa, chữ thường, có hoặc không có ngoặc nhọn `{}`, có hoặc không có gạch nối.

## 6. Ép kiểu (cast)
```sql
SELECT '42'::integer, CAST('42' AS integer), integer '42';   -- 3 cách viết tương đương
SELECT pg_typeof(7 / 2.0);                                   -- numeric   (hỏi Postgres: "biểu thức này kiểu gì?")
SELECT pg_input_is_valid('12a', 'integer');                  -- false     (kiểm tra trước, khỏi bị lỗi giữa chừng)
SELECT 'abc'::integer;                                       -- ERROR: invalid input syntax for type integer
```
Postgres **không có** `TRY_CAST` như SQL Server. Gặp một dòng ép kiểu thất bại là cả query lỗi.

---

## Bẫy hay gặp

**1. Tiền bằng float, so sánh bằng `=`**
```sql
WHERE amount = 0.3                         -- SAI với float: 0.1 + 0.2 lưu thành 0.30000000000000004
WHERE round(amount::numeric, 2) = 0.30     -- ĐÚNG: đưa về numeric, làm tròn đến đơn vị nhỏ nhất rồi mới so
```

**2. Ép kiểu sau khi đã tràn**
```sql
SELECT (2147483647 + 1)::bigint;           -- SAI: vẫn lỗi, vì phép cộng đã tính bằng integer trước khi ép
SELECT 2147483647::bigint + 1;             -- ĐÚNG: ép một toán hạng TRƯỚC khi tính
```
Bẫy tương tự với phép chia: `(7 / 2)::numeric` ra `3`, không phải `3.5`.

**3. Ép `timestamp` sang `timestamptz` bằng `::`**
```sql
-- giờ VN lưu bằng timestamp, session đang ở UTC
SELECT timestamp '2026-01-01 07:00'::timestamptz;                          -- SAI: 2026-01-01 07:00+00, lệch 7 tiếng
SELECT timestamp '2026-01-01 07:00' AT TIME ZONE 'Asia/Ho_Chi_Minh';       -- ĐÚNG: 2026-01-01 00:00+00
```
`::timestamptz` hiểu giá trị theo múi giờ **của session**, không phải múi giờ thật của dữ liệu.

**4. `AT TIME ZONE '+07'` cho ra UTC−7**
```sql
SELECT timestamptz '2026-01-01 00:00+00' AT TIME ZONE '+07';               -- SAI: 2025-12-31 17:00 (!)
SELECT timestamptz '2026-01-01 00:00+00' AT TIME ZONE 'Asia/Ho_Chi_Minh';  -- ĐÚNG: 2026-01-01 07:00
```
Chuỗi múi giờ kiểu `'+07'` hoặc `'UTC+7'` được hiểu theo chuẩn POSIX, mà POSIX lại **đảo dấu** (dương là phía tây). Hãy dùng tên vùng (`Asia/Ho_Chi_Minh`) hoặc `interval '+07:00'`. Ghi chú thêm: image hiện tại **không có** tên cũ `Asia/Saigon`, đây cũng là nguyên nhân DBeaver báo lỗi.

**5. Chuỗi ngày mơ hồ**: `'09-01-2026'` là 1/9 hay 9/1 tùy `DateStyle`. Chỉ dùng ISO `'2026-09-01'`. (Đây là lỗi của ex09 ở F01.)

## Postgres khác gì MySQL / SQL Server?
- **Chia số nguyên:** MySQL `7 / 2` ra `3.5000` (muốn chia lấy nguyên phải viết `7 DIV 2`). Postgres và SQL Server ra `3`.
- **Boolean:** MySQL dùng `TINYINT(1)`, SQL Server dùng `BIT`. Postgres có kiểu `boolean` thật.
- **Thời gian:** `TIMESTAMP` của MySQL tự đổi theo múi giờ, còn `DATETIME` thì không. SQL Server có `datetimeoffset`. Postgres là `timestamptz`.
- **UUID:** SQL Server có `uniqueidentifier`. MySQL không có kiểu UUID riêng, thường lưu bằng `BINARY(16)` hoặc `CHAR(36)`.
- **Tràn số:** MySQL ở chế độ không strict có thể lặng lẽ cắt giá trị. Postgres luôn báo lỗi.
