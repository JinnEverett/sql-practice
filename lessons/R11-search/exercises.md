# R11 · Bài tập (Search)

Bài 1, 2, 7 chạy trên **`shop_s`**; bài 3 trên DB **`lab`** schema `r11` (script chấm tự chạy `setup.sql`); bài 4, 5, 6 trên **`shop_m`** (20 000 sản phẩm, 100 000 user); bài 8 là câu hỏi quy mô (tự đối chiếu).
Bài 5, 6 là DDL (bộ chấm chạy rồi ROLLBACK). Tên sản phẩm có dạng `Tai nghe Sony 0252` (loại + hãng + mã hex); tìm kiếm trên cột `name`.
Tự chấm: `bash tools/check.sh lessons/R11-search 01`.

**Pass:** 6/8 (7 bài chấm tự động + ex08 tự đối chiếu số đo). ROADMAP: "Search đúng + có index" = ex06 + ex05.

---

## 🟢 Cơ bản

### ex01 · Full-text căn bản
Trên `shop_s`, tìm sản phẩm có tên chứa **cả hai từ** "tai" và "nghe" (không phân biệt hoa/thường, không cần đứng cạnh nhau). Dùng full-text search với cấu hình `'simple'`.
- Cột: `id, name` · Sắp xếp: `id`
- Kỳ vọng: **5 dòng**, dòng đầu `23 | Tai nghe Samsung 3769`

### ex02 · Gom từ khóa tìm kiếm có dấu và không dấu
Trong `events` (loại `search`), `properties->>'query'` có cả "áo thun" lẫn "ao thun". Chuẩn hóa (chữ thường, bỏ dấu), đếm số lượt tìm và số cách viết khác nhau của mỗi từ khóa chuẩn hóa.
- Cột: `normalized_query, n_searches, n_variants` · Sắp xếp: `n_searches` giảm dần, `normalized_query`
- Kỳ vọng: **10 dòng**; từ khóa "ao thun" có `n_variants = 2`

---

## 🟡 Kết hợp

### ex03 · Xếp hạng có trọng số
`r11.articles(id, title, body)`. Tìm bài chứa cụm "chỉ mục" (cả hai từ, người dùng gõ có dấu nhưng dữ liệu cần so khớp bỏ dấu). Xếp hạng bằng `ts_rank_cd`, **tiêu đề trọng số A, nội dung trọng số B**. Làm tròn rank 4 chữ số.
- Cột: `id, title, rank` · Sắp xếp: `rank` giảm dần, `id`
- Kỳ vọng: **7 dòng**, dòng đầu `10 | Chỉ mục một phần | 2.1238`

### ex04 · Tìm mờ chịu gõ sai
Trên `shop_m`, người dùng gõ `op lung samsug` (không dấu, sai chữ). Lấy 5 sản phẩm giống nhất theo `pg_trgm` (dùng toán tử `%` để lọc), so khớp trên dạng chữ thường không dấu của `name`. Làm tròn similarity 3 chữ số.
- Cột: `id, name, sim` · Sắp xếp: `sim` giảm dần, `id`
- Kỳ vọng: **5 dòng**, dòng đầu `313 | Ốp lưng Samsung 158F | 0.619`

### ex05 · Tìm chuỗi con trên 100 000 user
Trên `shop_m`, tìm user có `full_name ILIKE '%nguyễn văn hải%'` (59 người) bằng `ORDER BY id`. Hiện đang Seq Scan 1 500 buffer. Viết `CREATE INDEX` phù hợp, rồi dòng `-- query`, rồi câu SELECT. Bộ chấm kiểm tra kết quả, plan có dùng index và không Seq Scan `users`, và số buffer đọc thấp.
Định dạng `answers/ex05.sql`:
```sql
CREATE INDEX …;
-- query
SELECT … ;
```
- Cột: `id, full_name`
- Kiểm tra bằng bộ test (index tạo trong transaction rồi ROLLBACK)

---

## 🔴 Thực tế

### ex06 · "Gõ 'ao thun' không ra 'Áo thun'" (shop_m)
Team báo: ô tìm kiếm sản phẩm không tìm được "Áo thun …" khi khách gõ không dấu, và tìm chậm. Trên `shop_m`: (1) tạo hàm `public.f_unaccent(text) RETURNS text` bỏ dấu và khai báo `IMMUTABLE`; (2) thêm cột sinh `products.search_vec tsvector` (`GENERATED ALWAYS AS … STORED`) = `to_tsvector('simple', f_unaccent(name))`; (3) tạo index GIN cho nó, để câu hỏi `search_vec @@ plainto_tsquery('simple', f_unaccent('ao thun'))` dùng được index và cho cùng kết quả với `áo thun`. Sản phẩm mới thêm vào phải tự tìm được.
- Kiểm tra bằng bộ test

### ex07 · Ô tìm kiếm kiểu Google
Người dùng nhập `"tai nghe" -sony` (cụm "tai nghe" liền nhau, loại trừ Sony). Trên `shop_s`, trả sản phẩm thỏa, so khớp trên tên đã bỏ dấu. Câu lệnh không được lỗi dù người dùng nhập bất kỳ chuỗi nào.
- Cột: `id, name` · Sắp xếp: `id`
- Kỳ vọng: **4 dòng**, dòng đầu `23 | Tai nghe Samsung 3769`

---

## 📏 ex08 · Câu hỏi quy mô: index tìm kiếm
Ba truy vấn đếm trên `users` (100k ở m) và `events` (3.2M ở m):
```sql
-- Q1
SELECT count(*) FROM users WHERE full_name ILIKE '%nguyễn văn hải%';
-- Q2
SELECT count(*) FROM users WHERE to_tsvector('simple', full_name) @@ plainto_tsquery('simple', 'văn hải');
-- Q3
SELECT count(*) FROM events WHERE event_type = 'search' AND properties->>'query' ILIKE '%giày chạy%';
```
1. **Dự đoán** (ghi vào `answers/ex08.md`): với mỗi truy vấn, loại index nào phù hợp (trigram, tsvector, partial?) và nhanh gấp bao nhiêu lần ở `s` và `m`? Truy vấn nào hưởng lợi ít nhất và vì sao?
2. Đo bằng `EXPLAIN (ANALYZE, BUFFERS)` (index tạo trong transaction rồi ROLLBACK; `solutions/ex08.sql`).
3. Giải thích điểm gãy (ở `s` planner có dùng index không?) và so sánh dung lượng index.

Lời giải và số đo thật: `solutions/ex08.md`.
