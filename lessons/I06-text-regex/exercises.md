# I06 · Bài tập (Text & regex)

Tất cả chạy trên **`shop_s`** (đã có sẵn extension `unaccent` và `pg_trgm`). Mỗi bài một câu lệnh vào `answers/exNN.sql`.
Tự chấm: `bash tools/check.sh lessons/I06-text-regex 01`.

**Pass:** 8/10 (9 bài chấm tự động + ex10 câu hỏi quy mô tự đối chiếu).

---

## 🟢 Cơ bản

### ex01 · Tìm tai nghe
Sản phẩm **đang bán** có tên chứa cụm "tai nghe", **không phân biệt hoa thường**.
- Cột: `id, name, price` · Sắp xếp: `id`
- Kỳ vọng: **4 dòng**, dòng đầu `23 | Tai nghe Samsung 3769 | 1555000.00`

### ex02 · Định dạng số điện thoại
Phân loại số điện thoại của khách bằng **regex**: `'nội địa 0xxxxxxxxx'` (số 0 rồi đúng 9 chữ số), `'quốc tế +84'` (`+84`, một khoảng trắng, đúng 9 chữ số), không có số là `'(trống)'`, còn lại `'khác'`. Chỉ hiện các nhóm có dữ liệu.
- Cột: `dinh_dang, n_users` · Sắp xếp: `n_users` giảm dần
- Kỳ vọng: **3 dòng**, dòng đầu `nội địa 0xxxxxxxxx | 678`

### ex03 · Chuẩn hóa về E.164
Với khách `id ≤ 60` có số điện thoại: đưa về dạng **E.164** `+84` + 9 chữ số, không khoảng trắng (`0926865138` → `+84926865138`, `+84 954511385` → `+84954511385`).
- Cột: `id, phone, phone_e164` · Sắp xếp: `id`
- Kỳ vọng: **34 dòng**, dòng đầu `3 | 0926865138 | +84926865138`

---

## 🟡 Kết hợp

### ex04 · Gộp từ khóa có dấu và không dấu
Từ khóa tìm kiếm nằm ở `events.properties->>'query'` (event `search`). Khách gõ cả có dấu lẫn không dấu (`áo thun` / `ao thun`). Chuẩn hóa: **bỏ dấu**, chữ thường, bỏ khoảng trắng hai đầu. Với mỗi từ khóa chuẩn hóa: tổng lượt tìm và số **cách gõ gốc khác nhau**.
- Cột: `query_norm, n_searches, n_variants` · Sắp xếp: `n_searches` giảm dần, trùng thì `query_norm`
- Kỳ vọng: **10 dòng**, dòng đầu `ao thun | 470 | 2`

### ex05 · Tên phổ biến nhất
Tên (từ **cuối cùng** của `full_name`) phổ biến nhất trong khách hàng. Bỏ khách không có tên. Họ tên có thể có 2, 3 hay 4 từ.
- Cột: `ten, n_users` · Sắp xếp: `n_users` giảm dần, trùng thì `ten` · Lấy 10 dòng
- Kỳ vọng: **10 dòng**, dòng đầu `Quang | 39`

### ex06 · Tóm tắt đơn hàng
Với các đơn `id ≤ 5`: số dòng hàng và chuỗi mô tả `tên × số lượng`, các món ngăn bởi `', '`, **theo thứ tự `line_no`**.
- Cột: `order_id, n_lines, items` · Sắp xếp: `order_id`
- Kỳ vọng: **5 dòng**, dòng đầu `1 | 4 | Trà Trung Nguyên D67D × 1, Sandal Coolmate F899 × 1, Áo nam Biti's 33E7 × 2, Ốp lưng Apple 140F × 4`

---

## 🔴 Thực tế

### ex07 · Email cần làm sạch
Tìm email có **chữ hoa** hoặc **khoảng trắng thừa ở đầu/cuối**. `issue` là `'chữ hoa'`, `'khoảng trắng'` hoặc `'cả hai'`.
- Cột: `id, email, issue` · Sắp xếp: `id`
- Kỳ vọng: **5 dòng**, dòng đầu `7 | MINH.TRAN4@YAHOO.COM | chữ hoa`

### ex08 · Kiểm tra slug danh mục
Quy tắc sinh slug: bỏ dấu, chữ thường, mỗi cụm ký tự không phải `a-z`/`0-9` thay bằng **một** dấu `-`, bỏ `-` ở hai đầu (`Nhà cửa & Đời sống` → `nha-cua-doi-song`). Liệt kê các danh mục có `slug` hiện tại **khác** slug sinh theo quy tắc.
- Cột: `id, name, slug, generated` · Sắp xếp: `id`
- Kỳ vọng: **1 dòng**: `7 | Mẹ & Bé | me-va-be | me-be`

### ex09 · Từ được tìm nhiều nhất
Tách mọi từ khóa tìm kiếm (đã bỏ dấu, chữ thường) thành **từng từ** (ngăn bởi khoảng trắng), đếm số lần mỗi từ xuất hiện.
- Cột: `token, n` · Sắp xếp: `n` giảm dần, trùng thì `token` · Lấy 10 dòng
- Kỳ vọng: **10 dòng**, dòng đầu `ao | 470`

---

## 📏 ex10 · Câu hỏi quy mô: `ILIKE '%…%'` trên 32 triệu event
```sql
SELECT count(*) FROM events WHERE event_type = 'search' AND properties->>'query' ILIKE '%thun%';
```
1. **Dự đoán** (ghi vào `answers/ex10.md`): thời gian ở `s`, `m`, `l`? Index B-tree trên `(properties->>'query')` có giúp được không? Index GIN trigram thì sao, nhanh hơn bao nhiêu lần?
2. Đo bằng `bench/bench.sh <file> --scales s,m,l --runs 1`. Thử index trên `shop_m` trong transaction:
   `BEGIN; CREATE INDEX ON events USING gin ((properties->>'query') gin_trgm_ops) WHERE event_type = 'search'; EXPLAIN (ANALYZE, BUFFERS) …; ROLLBACK;`
3. Vì sao index trigram ở đây **không** nhanh hơn hàng trăm lần như index ở I05 ex10?

Lời giải và số đo thật: `solutions/ex10.md`.
