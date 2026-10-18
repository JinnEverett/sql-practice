# F04 · Review (2026-10-12)

**Kết quả: ✅ đạt, 10/10, 0 hint.** Đúng ngay lần nộp đầu: 3/10 (ex01, ex02, ex09).
Có **5 bài** ❌ ở lần nộp đầu **chỉ vì tên cột hoặc nhãn lệch đề**, logic đều đúng.

| Bài | Kết quả | Số lần nộp | Ghi chú |
|---|---|---|---|
| ex01 | ✅ | 1 | Viết `count(status)`; `count(*)` mới đúng ý "đếm đơn" (status NOT NULL nên kết quả trùng) |
| ex02 | ✅ | 1 | `count(city)`, `count(deleted_at)` thay cho WHERE/FILTER, có tiêu chí phụ `country` |
| ex03 | ✅ | 2 | Lần 1 thiếu alias `n_active`. Lọc `is_active` ở `WHERE` nên min/max đúng phạm vi |
| ex04 | ✅ | 2 | Lần 1 gõ `n_payment`. `100.0 *` đặt trước phép chia; `nullif` thừa nhưng vô hại |
| ex05 | ✅ | 2 | Lần 1 gõ `n_user`. `count(user_id)` và `count(DISTINCT user_id)` đúng chỗ |
| ex06 | ✅ | 3 | Lần 1–2 `date_trunc` theo UTC (tháng 1 ra 358 thay vì 355), dù `WHERE` đã theo giờ VN. Lần 3 tự sửa bằng `AT TIME ZONE` |
| ex07 | ✅ | 3 | Lần 1 sót `total_discount` + nhãn thiếu ngoặc; lần 2 vẫn thiếu ngoặc, thêm `round(sum)` thừa |
| ex08 | ✅ | 3 | `string_agg(... ORDER BY line_no)` đúng ngay; tên cột `products_id` → `products_ids` → `product_ids`. Hai lần dán nhầm query cũ |
| ex09 | ✅ | 1 | Bài 🔴, đủ 4 điều kiện in đậm, giờ VN, `>=`, WHERE/HAVING đúng vai trò |
| ex10 | ✅ | 2 | Lần 1 nhóm trên `orders` (không có status `succeeded`, nhóm theo PK luôn 1 dòng). Sau khi xem `\d payments` thì đúng; tránh bẫy 1070 đơn nhờ lọc ở `WHERE` |

Warm-up: câu 1 (`NOT IN` có NULL) ❌, trả lời 2, đúng là 0 · câu 2 hoãn.
Bonus quy mô ex06: chưa làm.

## Nắm chắc
- `GROUP BY` + `HAVING` vs `WHERE`: đặt đúng điều kiện dòng/nhóm ở cả 10 bài, kể cả bài 🔴 ex09 đúng ngay.
- Ba loại `count` (`*`, `col`, `DISTINCT col`) và `FILTER`; chia tỉ lệ không bị cắt số nguyên.
- `string_agg` có `ORDER BY` bên trong, ép `::text`.

## Cần cải thiện
- **Tên cột/nhãn output** (`doc-thieu-de`, +5 trong buổi): sai ở ex03, ex04, ex05, ex07, ex08, có bài sai 2 lần liên tiếp. Tự chạy `check.sh` trước khi nộp sẽ bắt được ngay.
- **Múi giờ khi nhóm** (`literal-thoi-gian`): mốc lọc đã đúng giờ VN nhưng `date_trunc` vẫn cắt theo UTC. `WHERE` và `GROUP BY` phải dùng cùng một múi giờ.
- **Xác định bảng chứa "sự vật cần đếm"** (`doan-ten-cot`): ex10 đếm "lần thanh toán" trên `orders`. Trước khi viết, hỏi: mỗi dòng của bảng này là một cái gì?

Lỗi ghi vào weaknesses: `doc-thieu-de` (+5), `null-so-sanh` (+1, warm-up), `literal-thoi-gian` (+1, ex06), `doan-ten-cot` (+1, ex10). Streak đúng: `chia-so-nguyen` (ex04, đạt 3 → khắc phục), `dich-de-chinh-xac` (ex09).
