# R02 · Bài tập (Keyset pagination)

Bài 1, 2 chạy trên **`shop_s`**; bài 3–7 trên DB **`lab`** schema `r02` (script chấm tự chạy `setup.sql`); bài 8 trên **`shop_m`**; bài 9 là câu hỏi quy mô (tự đối chiếu).
Mỗi bài một câu lệnh vào `answers/exNN.sql` (bài 6, 8 gồm nhiều câu). Tự chấm: `bash tools/check.sh lessons/R02-keyset-pagination 01`.

**Pass:** 8/9 (8 bài chấm tự động + ex09 tự đối chiếu số đo).

---

## 🟢 Cơ bản

### ex01 · Trang 5 bằng OFFSET
Danh sách đơn mới nhất trước, mỗi trang 10 đơn. Lấy **trang 5**.
- Cột: `id, created_at, status, total_amount` · Sắp xếp: `created_at` giảm dần, trùng thì `id` giảm dần
- Kỳ vọng: **10 dòng** (đơn thứ 41 đến 50 của danh sách)

### ex02 · Trang kế tiếp bằng keyset
Người dùng vừa xem trang 1 (10 đơn). Dòng cuối của trang là đơn `id = 9991`, `created_at = '2026-09-30 09:45:28.287597+00'`. Lấy **trang 2** bằng keyset, không dùng OFFSET.
- Cột: như ex01 · Sắp xếp: như ex01
- Kỳ vọng: **10 dòng**, trùng với `LIMIT 10 OFFSET 10` của ex01

---

## 🟡 Kết hợp

### ex03 · Cursor nằm giữa nhóm trùng giờ
`r02.feed(id, created_at, title)`: cứ 5 bài liền nhau có cùng `created_at`. Feed sắp xếp mới nhất trước. Dòng cuối trang trước là bài `id = 103` lúc `2026-01-01 00:20+00`. Lấy 7 bài tiếp theo, không bỏ sót và không lặp bài nào.
- Cột: `id, created_at, title` · Sắp xếp: `created_at` giảm dần, `id` giảm dần
- Kỳ vọng: **7 dòng**, dòng đầu `102 | 2026-01-01 00:20:00+00 | Bài 101`

### ex04 · Cột sắp xếp có NULL
`r02.members(id, name, birth_date)` có 15 người không có ngày sinh. Danh sách sắp xếp `birth_date` giảm dần, **NULL cuối**, trùng thì `id` tăng dần. Lấy 8 dòng tiếp theo cho hai cursor, gộp vào một kết quả với cột `case_no`:
- `'A'`: dòng cuối trang trước là `id = 6`, `birth_date = 1990-03-02`. Trang này đi qua ranh giới từ người có ngày sinh sang NULL.
- `'B'`: dòng cuối trang trước là `id = 20`, `birth_date` NULL.
- Cột: `case_no, id, birth_date` · Sắp xếp: `case_no`, rồi đúng thứ tự danh sách (birth_date giảm dần NULL cuối, id tăng dần)
- Kỳ vọng: **16 dòng**, dòng đầu `A | 26 | 1990-03-02`; dòng đầu của B là `B | 24 | (NULL)`

### ex05 · Hướng sắp xếp hỗn hợp
`r02.tickets(id, status, created_at)` sắp xếp `status` **tăng dần**, `created_at` **giảm dần**, `id` giảm dần. Dòng cuối trang trước: `id = 12`, `status = 'open'`, `created_at = 2026-02-01 02:00+00`. Lấy 6 dòng tiếp theo (đi qua ranh giới sang `pending`).
- Cột: `id, status, created_at` · Sắp xếp: đúng thứ tự danh sách
- Kỳ vọng: **6 dòng**, dòng đầu `51 | open | 2026-02-01 01:00:00+00`

### ex06 · Hàm phân trang ổn định
Viết hàm `r02.feed_page(p_ts timestamptz, p_id bigint, p_size int)` trả về bảng `(id bigint, created_at timestamptz, title text)` là `p_size` bài tiếp theo sau cursor `(p_ts, p_id)` theo thứ tự mới nhất trước; `p_ts` NULL nghĩa là trang đầu. Bộ chấm đọc hết feed từng trang 13 bài trong khi sau mỗi trang có 2 bài mới được đăng, rồi kiểm tra không mất, không lặp bài nào.
- Kiểm tra bằng bộ test

### ex07 · Trang trước
Người dùng đang xem trang có **dòng đầu** là `id = 52`, `created_at = '2026-01-01 00:10+00'` (feed sắp mới nhất trước). Lấy 7 bài của **trang trước** đó, hiển thị theo thứ tự thường lệ (mới nhất trước).
- Cột: `id, created_at, title` · Sắp xếp: `created_at` giảm dần, `id` giảm dần
- Kỳ vọng: **7 dòng**, dòng đầu `59 | 2026-01-01 00:11:00+00 | Bài 58`

---

## 🔴 Thực tế

### ex08 · "Lịch sử đơn của khách chậm khi cuộn"
Team báo: app hiện lịch sử đơn của khách theo kiểu cuộn vô hạn, mỗi lần 20 đơn. Với khách `user_id = 200` và cursor `(created_at = '2026-01-01 00:00+00', id = 900000)`, trang kế tiếp mất cả chục ms dù khách chỉ có ~250 đơn. Trên **`shop_m`**: viết `CREATE INDEX` phù hợp, rồi dòng `-- query`, rồi câu SELECT lấy trang (sắp xếp `created_at` giảm dần, `id` giảm dần). Bộ chấm kiểm tra kết quả, plan không có `Seq Scan` và `Sort`, và số buffer đọc thấp.
Định dạng `answers/ex08.sql`:
```sql
CREATE INDEX …;
-- query
SELECT … ;
```
- Cột: `id, created_at, total_amount`
- Kiểm tra bằng bộ test (index được tạo trong transaction rồi ROLLBACK)

---

## 📏 ex09 · Câu hỏi quy mô: OFFSET sâu
```sql
SELECT id, created_at, total_amount FROM orders ORDER BY created_at DESC, id DESC LIMIT 20 OFFSET :k;
```
1. **Dự đoán** (ghi vào `answers/ex09.md`): với `k` = 0, 10%, 50%, 90% số đơn, thời gian ở `s`, `m` và `l` (10M) khi (a) không có index, (b) có index `(created_at DESC, id DESC)`. Keyset tương ứng mất bao lâu? Plan có đổi không, có tràn đĩa không?
2. Đo ở `shop_s` và `shop_m` bằng `EXPLAIN (ANALYZE, BUFFERS)` hoặc `bench/bench.sh` (index tạo trong transaction hoặc tạo rồi DROP).
3. Giải thích đường cong: chi phí của OFFSET tăng theo gì? Điều gì khiến keyset phẳng?

Lời giải và số đo thật: `solutions/ex09.md`.
