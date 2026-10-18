# I05 · Date/time deep dive

Đọc khoảng 10 phút. Ví dụ chạy trên `shop_s`. Server chạy **UTC**, như phần lớn hệ thống production.

## Mục tiêu: sau buổi này bạn làm được
- Hiểu `timestamptz` và `timestamp` thật sự lưu gì, và `AT TIME ZONE` đổi chiều nào.
- Làm việc với nhiều múi giờ, kể cả múi giờ có **giờ mùa hè (DST)**.
- Dùng `interval`, `date_trunc` (ngày/tuần ISO/tháng), `extract`, `age`, `justify_*`.
- **Lấp khoảng trống** bằng `generate_series` (ngày, giờ, lưới khách × tháng).
- Viết điều kiện thời gian **dùng được index** (sargable).

---

## 1. Hai kiểu timestamp
| | `timestamptz` | `timestamp` (without time zone) |
|---|---|---|
| Lưu gì | một **thời điểm tuyệt đối** (nội bộ là UTC) | "giờ trên đồng hồ treo tường", không gắn múi giờ |
| Hiển thị | đổi sang `TimeZone` của session | in nguyên như đã lưu |
| Dùng cho | thời điểm sự kiện (đặt đơn, thanh toán) | giờ mở cửa "8:00 mọi chi nhánh", lịch lặp |

`AT TIME ZONE` đổi **qua lại** giữa hai kiểu:
```sql
SELECT timestamptz '2026-09-15 00:30+07'                                  AS goc,        -- 2026-09-14 17:30:00+00 (session UTC)
       timestamptz '2026-09-15 00:30+07' AT TIME ZONE 'Asia/Ho_Chi_Minh'  AS dong_ho_vn, -- 2026-09-15 00:30:00 (timestamp)
       timestamp   '2026-09-15 00:30'    AT TIME ZONE 'Asia/Ho_Chi_Minh'  AS thoi_diem;  -- 2026-09-14 17:30:00+00 (timestamptz)
```
- `timestamptz AT TIME ZONE z` → `timestamp`: "lúc đó đồng hồ ở z chỉ mấy giờ". Dùng trước `date_trunc`, `::date`, `extract`.
- `timestamp AT TIME ZONE z` → `timestamptz`: "giờ đồng hồ này ở z là thời điểm nào".
- Đổi TimeZone của session (`SET TimeZone = 'Asia/Ho_Chi_Minh'`) chỉ đổi **cách hiển thị** và cách hiểu literal thiếu múi giờ. Dữ liệu không đổi. Đừng dựa vào nó trong code: mỗi kết nối có thể cài một kiểu khác nhau.

## 2. Múi giờ và DST
```sql
SELECT z, timestamptz '2026-01-15 12:00+00' AT TIME ZONE z AS thang1,
          timestamptz '2026-07-15 12:00+00' AT TIME ZONE z AS thang7
FROM unnest(ARRAY['Asia/Ho_Chi_Minh', 'Australia/Sydney', 'America/Los_Angeles']) AS z;
-- Sydney: +11 vào tháng 1 (mùa hè Nam bán cầu), +10 vào tháng 7. Los Angeles: −8 rồi −7.
```
- Luôn dùng **tên vùng IANA** (`Australia/Sydney`). Offset cố định (`+10`) đúng được nửa năm. Bẫy thêm: chuỗi POSIX `'+10'` trong `AT TIME ZONE` lại có **dấu ngược** với ISO.
- Tên múi giờ có thể lấy từ **một cột**: `created_at AT TIME ZONE u.timezone`.
- Việt Nam không có DST, nên `+07` và `Asia/Ho_Chi_Minh` cho kết quả giống nhau.

## 3. `interval` và phép tính
```sql
SELECT timestamptz '2026-10-01 00:00+07' - interval '3 days',      -- lùi 3 ngày
       date '2026-01-31' + interval '1 month',                      -- 2026-02-28 00:00:00 (cắt về cuối tháng)
       date '2026-10-01' - date '2026-09-01',                       -- 30 (int: số ngày)
       timestamptz '2026-10-01 00:00+07' - timestamptz '2026-09-01 12:00+07',   -- 29 days 12:00:00 (interval)
       justify_hours(interval '100 hours'),                         -- 4 days 04:00:00
       extract(epoch FROM interval '1 day 6 hours') / 3600;         -- 30 (giờ)
```
- `interval '1 day'` và `interval '24 hours'` **khác nhau** khi đi qua ngày đổi giờ DST.
- Đổi interval ra số để so sánh hoặc tính trung bình: `extract(epoch FROM x)` cho ra số giây.

## 4. Cắt và trích
| Việc | Cách viết (giờ VN) |
|---|---|
| Đầu ngày / tháng / năm | `date_trunc('day' / 'month' / 'year', ts AT TIME ZONE 'Asia/Ho_Chi_Minh')` |
| Đầu tuần (thứ Hai, ISO) | `date_trunc('week', …)` |
| Nhãn tuần ISO | `to_char(…, 'IYYY-"W"IW')`. Dùng **IYYY**, không dùng YYYY: ngày 29/12/2025 thuộc tuần `2026-W01` |
| Thứ / giờ / phút | `extract(isodow / hour / minute FROM …)` |
| Tuổi, khoảng cách lịch | `age(a, b)` → `"1 year 2 mons 3 days"` |

## 5. Lấp khoảng trống bằng `generate_series`
```sql
-- đủ mọi ngày, kể cả ngày không có dữ liệu
SELECT d::date, count(o.id)
FROM generate_series(date '2026-09-01', date '2026-09-07', interval '1 day') d
LEFT JOIN orders o ON (o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date = d::date
GROUP BY d ORDER BY d;

-- lưới đầy đủ: mỗi khách × mỗi tháng
SELECT u.id, m FROM users u CROSS JOIN generate_series(timestamp '2026-01-01', timestamp '2026-03-01', interval '1 month') m
WHERE u.id <= 2;
```
- Luôn bắt đầu từ **bảng lịch**, rồi LEFT JOIN dữ liệu vào.
- Sau LEFT JOIN, đếm bằng `count(cột_của_bảng_phải)`. `count(*)` sẽ đếm cả dòng NULL thành 1.
- `generate_series(0, 23)` sinh dãy số nguyên (24 khung giờ).

## 6. Điều kiện thời gian dùng được index
```sql
WHERE (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date = '2026-09-15'           -- ✗ bọc cột → không dùng được index
WHERE created_at >= '2026-09-15 00:00+07' AND created_at < '2026-09-16 00:00+07'  -- ✓ cột trần, khoảng nửa mở
```
Đổi **hằng số** cho khớp với cột, đừng đổi **cột** cho khớp với hằng số. Số đo thật ở ex10.

## Bẫy hay gặp
1. `::date`, `date_trunc`, `extract` trên `timestamptz` mà không `AT TIME ZONE` → ra kết quả theo UTC.
2. Offset cố định cho múi giờ có DST.
3. Năm lịch `YYYY` đi kèm tuần ISO `IW`.
4. Lấp khoảng trống mà bắt đầu từ bảng dữ liệu → ô trống không bao giờ xuất hiện.
5. `now()` trong bài kiểm chứng → kết quả đổi theo ngày chạy. Dùng mốc cố định.

## Postgres-specific
- `generate_series`, `date_trunc`, `justify_*`, `age`, `AT TIME ZONE` với tên vùng IANA đều có sẵn. MySQL cần `CONVERT_TZ` và phải nạp bảng múi giờ trước.
- `now()` trả về thời điểm **bắt đầu transaction** (không đổi suốt transaction). `clock_timestamp()` trả về giờ thực mỗi lần gọi.
