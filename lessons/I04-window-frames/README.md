# I04 · Window function II: LAG/LEAD, lũy kế, frame

Đọc khoảng 10 phút. Ví dụ chạy trên `shop_s`.

## Mục tiêu: sau buổi này bạn làm được
- So một dòng với dòng **trước/sau** nó bằng `lag`/`lead`: khoảng cách giữa hai đơn, tăng trưởng so với kỳ trước.
- Tính **lũy kế** và **trung bình trượt** bằng frame `ROWS BETWEEN … AND …`.
- Hiểu **frame mặc định** và hai cái bẫy kinh điển của nó: `last_value` và RANGE gộp các dòng đồng hạng (peers).
- Lấy giá trị đầu/cuối nhóm bằng `first_value`, `last_value`, `nth_value`.

---

## 1. `lag` / `lead`
```sql
SELECT id, created_at,
       lag(created_at)       OVER w AS prev_at,     -- dòng trước
       lead(id)              OVER w AS next_id,     -- dòng sau
       lag(total_amount, 2, 0) OVER w AS two_back   -- lùi 2 dòng, mặc định 0 nếu không có
FROM orders WHERE user_id = 25
WINDOW w AS (PARTITION BY user_id ORDER BY created_at, id)
ORDER BY created_at LIMIT 4;
```
- `lag(x, n, default)`: lấy x của dòng cách n dòng **về trước** trong partition. `lead` là về sau.
- Mệnh đề `WINDOW w AS (…)` đặt tên cho một window để dùng lại nhiều lần.
- `lag(revenue, 12)` trên bảng tháng là "cùng kỳ năm trước". Điều này chỉ đúng khi **không thiếu tháng nào**: n dòng, không phải n tháng.

## 2. Frame: cửa sổ trượt
Frame là tập dòng mà hàm tổng hợp "nhìn thấy" khi tính cho dòng hiện tại.
```sql
sum(x)  OVER (ORDER BY ngay ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)   -- lũy kế
avg(x)  OVER (ORDER BY ngay ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)           -- trung bình 7 dòng gần nhất
sum(x)  OVER (ORDER BY ngay ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)           -- dòng trước + hiện tại + dòng sau
max(x)  OVER (PARTITION BY nhom)                                                -- cả nhóm (không ORDER BY)
```
| đơn vị frame | ý nghĩa của "N PRECEDING" |
|---|---|
| `ROWS` | N **dòng** vật lý |
| `RANGE` | các dòng có giá trị ORDER BY trong khoảng `[hiện tại − N, hiện tại]`, ví dụ `RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW` |
| `GROUPS` | N **nhóm giá trị** (các dòng đồng hạng tính là một nhóm) |

- Trung bình "7 ngày" bằng `ROWS 6 PRECEDING` chỉ đúng khi **mỗi ngày có đúng một dòng**. Nếu có ngày thiếu dữ liệu, hãy lấp ngày trước (I05) hoặc dùng `RANGE … INTERVAL '6 days'` trên cột kiểu date/timestamp.
- Window chạy **sau** `WHERE`. Ngày đầu của khoảng cần dữ liệu những ngày trước đó, nên phải lấy rộng hơn ở tầng trong và lọc ở tầng ngoài (ex03, ex07).

## 3. ⚠️ Frame mặc định
- **Không có `ORDER BY`** trong `OVER`: frame là **cả partition**. `avg(price) OVER (PARTITION BY category_id)` cho trung bình cả danh mục.
- **Có `ORDER BY`**: frame mặc định là `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`, tức từ đầu tới dòng hiện tại **kể cả các dòng đồng hạng (peers)**. Thêm `ORDER BY` vào là `avg` thành trung bình lũy kế.

Hai hệ quả hay làm sai:
```sql
-- (1) last_value với frame mặc định = chính dòng hiện tại
SELECT id, last_value(id) OVER (ORDER BY created_at) FROM orders WHERE user_id = 1 LIMIT 3;   -- cột 2 = cột 1 !
--     sửa: mở frame tới cuối
SELECT id, last_value(id) OVER (ORDER BY created_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
FROM orders WHERE user_id = 1 LIMIT 3;

-- (2) RANGE gộp peers: các dòng cùng giá trị ORDER BY nhận CÙNG một số lũy kế
SELECT (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS ngay,
       count(*) OVER (ORDER BY (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date) AS range_cum,
       count(*) OVER (ORDER BY (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date ROWS UNBOUNDED PRECEDING) AS rows_cum
FROM orders WHERE created_at >= '2026-09-01 00:00+07' AND created_at < '2026-09-02 00:00+07' LIMIT 3;
-- range_cum = 30, 30, 30 (cả ngày) · rows_cum = 1, 2, 3
```
Quy tắc:
- Muốn cộng **từng dòng một** (số dư tài khoản, tồn kho) thì dùng `ROWS` **và** `ORDER BY` phải duy nhất (thêm `id`).
- Muốn "tới hết ngày/nhóm đó" thì dùng `RANGE` (mặc định) trên cột nhóm.

## 4. `first_value`, `last_value`, `nth_value`
```sql
first_value(id) OVER w, last_value(id) OVER w, nth_value(id, 2) OVER w
WINDOW w AS (PARTITION BY user_id ORDER BY created_at, id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
```

## Bẫy hay gặp
1. `last_value` / `nth_value` với frame mặc định.
2. Lũy kế bằng frame mặc định khi ORDER BY có giá trị trùng → nhảy cóc (ex09).
3. Lọc khoảng thời gian ở cùng tầng với `lag` / trung bình trượt → đầu kỳ thiếu dữ liệu.
4. `lag(x, 12)` khi bảng tháng bị thiếu tháng.
5. Window trên bảng lớn vẫn là O(n). Index chỉ bỏ được bước Sort, không bỏ được việc xử lý từng dòng (ex10).

## Postgres-specific
- Postgres hỗ trợ đủ `ROWS`, `RANGE` (kể cả offset kiểu interval), `GROUPS` và `EXCLUDE CURRENT ROW / TIES`. MySQL 8 không có `GROUPS` và `EXCLUDE`.
