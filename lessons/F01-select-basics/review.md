# F01 · Review (2026-10-08)

**Kết quả: ✅ đạt, 9/10, 0 hint.** Ngưỡng pass là 8/10 bài và ≤ 2 hint.
ex09 không đạt: sau 3 lần nộp, người học xin đáp án. Đáp án nằm cuối `answers/ex09.sql`.

| Bài | Kết quả | Số lần nộp | Ghi chú |
|---|---|---|---|
| ex01 | ✅ | 1 | Có `id` làm tiêu chí phụ khi trùng giá. Lưu ý: dùng `DESC` thì NULL lên đầu |
| ex02 | ✅ | 1 | `like 'VN'` nên viết `=`. `extract(year …)` phụ thuộc TimeZone và không dùng được index, nên dùng khoảng nửa mở |
| ex03 | ✅ | 2 | Lần 1 thiếu `ORDER BY`, vì `DISTINCT` không bảo đảm thứ tự. Lần 1 còn JOIN lọc theo tên danh mục, lần 2 lọc theo `category_id` |
| ex04 | ✅ | 1 | Dùng `IN` nên tránh được bẫy độ ưu tiên `AND` > `OR` (viết sai sẽ ra 942 dòng thay vì 388) |
| ex05 | ✅ | 2 | Lần 1 thiếu lọc danh mục 9, 10. Câu hỏi phụ (thứ tự logic, alias trong WHERE): ✅ |
| ex06 | ✅ | 1 | `offset 10` đúng, có `id desc` làm tiêu chí phụ. User 1 là "khách cá voi" với 1007 đơn |
| ex07 | ✅ | 1 | Câu hỏi phụ: tự tìm ra 4 cách viết TP.HCM; điểm thứ hai (47 city NULL) tìm ra nhờ được gợi ý |
| ex08 | ✅ | 2 | Lần 1 lọc `brand ilike 'sony'`, pass nhờ dữ liệu trùng hợp (mọi tên sản phẩm đều chứa brand) |
| ex09 | 🔑 xin đáp án | 3 | Pass trên shop_s nhưng sai trên shop_m: thừa 54 đơn tháng 9 các năm trước (bản đầu), thiếu 1 đơn đúng 2 000 000. Còn lại: `>` → `>=`, literal kiểu MDY, thiếu múi giờ, thiếu `id` |
| ex10 | ✅ | 1 | `IS NULL` đúng. `WHERE` chạy trước `LIMIT` nên đủ 10 người dù có 1 người đã xóa tài khoản |

## 📏 Bonus ex06: OFFSET nhỏ và OFFSET lớn (shop_m, 1M đơn)

Dự đoán của người học: hai trang chạy như nhau, vì "đằng nào cũng chạy theo index" và "phải sort toàn bộ bảng". **Dự đoán sai.**

| | Trang 3 (`offset 10`) | Trang 100 000 (`offset 499995`) |
|---|---|---|
| Thời gian (median) | ~478 ms | ~803 ms |
| Sort | `top-N heapsort`, 27 kB | `external merge`, spill 67 MB temp |

- Bảng không có index trên `created_at`, chỉ có `orders_pkey (id)`. Index trên `id` không giúp được `ORDER BY created_at, id`, vì cột đầu của index phải trùng với cột đầu cần sort.
- Postgres phải đọc hết bảng, nhưng không phải sort hết: top-N chỉ giữ lại `offset + limit` dòng. OFFSET lớn thì số dòng phải giữ vượt `work_mem`, nên sort tràn ra đĩa.
- Dù có index, OFFSET lớn vẫn có chi phí O(offset). Cách chữa là keyset pagination, học ở Tier I/P.
- Kết quả đo: `bench/results/2026-10-08-f01-ex06-page{3,100k}.md`. Các lần đo chạy khi cache đã ấm.

## Nắm chắc
- `SELECT`, `WHERE`, `ORDER BY` nhiều cột có tiêu chí phụ, `LIMIT/OFFSET`, `DISTINCT`, `IN`, `ILIKE`, `IS NULL`.
- Thứ tự logic `FROM → WHERE → … → SELECT → ORDER BY → LIMIT`, nên alias không dùng được trong `WHERE`.
- Thói quen luôn có tiêu chí phụ khi sort đã hình thành từ ex01.

## Cần cải thiện
- **Dịch đề sát từng chữ** (`dich-de-chinh-xac`): ex08 và ex09 pass trên shop_s nhưng thực chất trả lời một câu hỏi khác. Trước khi viết `WHERE`, liệt kê từng điều kiện kèm toán tử ("trở lên" là `>=`, "chứa" là `%…%`).
- **Mốc thời gian** (`literal-thoi-gian`): luôn viết ISO kèm múi giờ (`'2026-09-01 00:00+00'`) và dùng khoảng nửa mở.
- **Đọc hết đề** (`doc-thieu-de`): ex03 thiếu `ORDER BY`, ex05 thiếu lọc danh mục.
- **Kiểm tra index trước khi giả định** (`mac-dinh-co-index`): dùng `\d` hoặc `EXPLAIN`.
