# F10 · Biểu thức: CASE, chuỗi, ngày giờ, định dạng

Đọc khoảng 10 phút. Ví dụ chạy trên `shop_s`.

## Mục tiêu: sau buổi này bạn làm được
- Dùng `CASE` để phân loại, đổi nhãn, sắp xếp theo thứ tự nghiệp vụ, và đếm có điều kiện.
- Làm sạch và tách chuỗi: `trim`, `lower`/`upper`, `substr`, `split_part`, `replace`, `lpad`, `||`, `concat_ws`.
- Tính toán ngày giờ: `age`, `extract`, `date_trunc`, phép cộng trừ `interval`, trừ hai `date`, **luôn theo đúng múi giờ**.
- Định dạng số và ngày bằng `to_char` mà không phụ thuộc cấu hình server.

---

## 1. `CASE`
```sql
-- dạng "searched": điều kiện tùy ý, xét từ trên xuống, nhánh ĐÚNG ĐẦU TIÊN thắng
SELECT name, price,
       CASE WHEN price < 100000  THEN 'rẻ'
            WHEN price < 1000000 THEN 'vừa'      -- không cần viết "price >= 100000 AND …"
            ELSE 'đắt' END AS muc_gia
FROM products LIMIT 3;

-- dạng "simple": so bằng với một giá trị
SELECT status, CASE status WHEN 'delivered' THEN 'đã giao' WHEN 'cancelled' THEN 'đã hủy' ELSE 'khác' END
FROM orders LIMIT 3;
```
- Thiếu `ELSE` thì giá trị không khớp nhánh nào thành **NULL**.
- Mọi nhánh phải cùng kiểu dữ liệu (`THEN 1 … ELSE 'x'` sẽ lỗi).
- `CASE` dùng được ở **mọi chỗ** đặt được biểu thức: `SELECT`, `WHERE`, `GROUP BY`, `ORDER BY`, bên trong `sum()`.
- Sắp theo thứ tự nghiệp vụ, không theo ABC: `ORDER BY CASE … THEN 1 … THEN 2 END`, hoặc `ORDER BY array_position(ARRAY['VIP','Thường'], hang)`, hoặc `ORDER BY min(price)` nếu thứ tự đi theo một cột số.

## 2. Chuỗi
| Hàm | Ví dụ | Kết quả |
|---|---|---|
| `lower`, `upper`, `initcap` | `initcap('nguyễn văn a')` | `Nguyễn Văn A` |
| `trim`, `ltrim`, `rtrim` | `trim('  a b  ')` · `ltrim('000123', '0')` | `a b` · `123` |
| `length` | `length('Huế')` | `3` (đếm ký tự, không đếm byte) |
| `substr(s, từ, dài)`, `left`, `right` | `substr('SKU-000123', 5)` · `right('0912345678', 3)` | `000123` · `678` |
| `split_part(s, sep, n)` | `split_part('an@gmail.com', '@', 2)` | `gmail.com` |
| `strpos(s, x)` | `strpos('an@gmail.com', '@')` | `3` |
| `replace`, `translate` | `replace('1.200.000', '.', '')` · `translate('a-b c', '- ', '')` | `1200000` · `abc` |
| `lpad(s, n, ký tự)` | `lpad('42', 6, '0')` | `000042` |
| `regexp_replace(s, mẫu, thay, 'g')` | `regexp_replace('+84 912', '^\+84\s*', '0')` | `0912` |

- Nối chuỗi bằng `||`: **chỉ cần một vế NULL là cả chuỗi thành NULL**. `concat(a, b)` và `concat_ws(' · ', a, b)` thì bỏ qua NULL.
- **Chuẩn hóa trước, rồi mới so sánh hoặc gom nhóm**: `lower(trim(email))`. Dữ liệu thật luôn lẫn chữ hoa và khoảng trắng thừa.
- Số → chuỗi: `id::text`. Chuỗi → số: `'000123'::int` (ra 123, mất luôn các số 0 đầu).

## 3. Ngày giờ: nhắc lại về múi giờ
Server chạy **UTC**. `timestamptz` lưu một **thời điểm tuyệt đối**, không lưu kèm múi giờ. Mọi phép "lấy ngày / tháng / thứ / giờ" đều tính theo **TimeZone của session** (ở đây là UTC), trừ khi bạn tự đổi:
```sql
SELECT created_at,                                              -- 2024-08-27 23:11:45+00
       created_at::date                         AS ngay_utc,    -- 2024-08-27  ← sai với nghiệp vụ VN
       (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS ngay_vn   -- 2024-08-28
FROM orders WHERE id = 146;
```
Quy tắc: **lọc** bằng literal có múi giờ (`'2026-01-01 00:00+07'`), còn **cắt/trích** thì đổi giờ trước bằng `AT TIME ZONE 'Asia/Ho_Chi_Minh'`.

| Việc | Cách viết |
|---|---|
| Cắt về đầu tháng (giờ VN) | `date_trunc('month', created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')` |
| Thứ trong tuần | `extract(isodow FROM …)`: 1 = Thứ 2 … 7 = Chủ nhật (`dow` thì Chủ nhật = 0) |
| Giờ trong ngày | `extract(hour FROM created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')` |
| Tuổi tròn | `extract(year FROM age(date '2026-10-01', birth_date))` |
| Số ngày giữa hai ngày | `date '2026-10-01' - date '2026-09-01'` → `30` (kiểu int) |
| Cộng thời gian | `created_at + interval '30 days'`, `date '2026-01-31' + interval '1 month'` → `2026-02-28 00:00:00` |
| Tạo ngày | `make_date(2026, 10, 19)` (lỗi nếu ngày không tồn tại, ví dụ 29/02/2026) |

- `age(a, b)` trả về interval kiểu "33 years 2 mons 4 days" và tính đúng việc **đã qua sinh nhật hay chưa**. Còn `2026 - năm sinh` có thể dư 1 tuổi.
- `extract` trả về kiểu `numeric`. Ép `::int` nếu cần số nguyên.

## 4. Định dạng: `to_char`
```sql
SELECT to_char(now() AT TIME ZONE 'Asia/Ho_Chi_Minh', 'DD/MM/YYYY HH24:MI'),   -- 17/10/2026 15:04
       to_char(1234567.5, 'FM999,999,999'),                                   -- 1,234,568
       replace(to_char(1234567.5, 'FM999,999,999'), ',', '.') || ' ₫';        -- 1.234.568 ₫
```
- Mẫu ngày: `YYYY YY MM DD HH24 MI SS`. Tên thứ/tháng (`Day`, `Month`) ra **tiếng Anh**, theo `lc_time` của server. Muốn tiếng Việt thì tự map bằng `CASE`.
- Mẫu số: `9` = chữ số, `FM` = bỏ khoảng trắng đệm. `G` và `D` lấy dấu phân cách theo `lc_numeric` của server (ở đây `en_US` nên ra `,` và `.`). Muốn chắc chắn ra kiểu VN thì viết `,` cố định rồi `replace`.
- `to_char` làm tròn khi mẫu không có phần lẻ.
- **Định dạng ở bước cuối cùng.** Sau `to_char`, giá trị là **chuỗi**: không còn cộng trừ được, và sắp xếp theo chữ (`'10/2026'` < `'9/2026'`). Vì vậy hãy `GROUP BY` / `ORDER BY` theo giá trị gốc.

## Bẫy hay gặp
1. `CASE` thiếu `ELSE` → các giá trị khác thành NULL.
2. `date_trunc` / `::date` / `extract` trên `timestamptz` mà không `AT TIME ZONE` → cắt theo UTC.
3. `ORDER BY` trên cột đã `to_char` → sắp theo chữ, sai thứ tự thời gian khi qua năm.
4. `a || NULL` → NULL. Kiểm tra mọi cột có thể NULL khi nối chuỗi.
5. Tính tuổi bằng hiệu hai năm → sai với người chưa tới sinh nhật trong năm.

## Postgres-specific
- MySQL có `DATE_FORMAT`, `IF()`, `CONCAT` với NULL ra NULL. Postgres dùng `to_char`, `CASE`, `||`.
- `split_part`, `regexp_replace`, `array_position`, `age` đều là hàm riêng của Postgres.
