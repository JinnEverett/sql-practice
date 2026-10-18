# F02 · Review (2026-10-09 → 2026-10-12)

**Kết quả: ✅ đạt, 10/10, 1 hint (H1 ở ex10).** Ngưỡng pass là 8/10 bài và ≤ 2 hint.
ex02–ex09 làm ngày 2026-10-09, buổi đó không ghi số lần nộp/hint; chấm lại bằng `check.sh` ngày 2026-10-12: đều ✅. ex01 và ex10 hoàn thành ngày 2026-10-12.

| Bài | Kết quả | Số lần nộp | Ghi chú |
|---|---|---|---|
| ex01 | ✅ | 3 (1 ngày 10-09) | 10-09: nộp 3 `SELECT` riêng, thiếu `float_eq`. 10-12: lần 1 lỗi cú pháp `:` thay cho `::` (2 chỗ), lần 2 đúng. Style: dùng lẫn `double precision` và `float8` |
| ex02 | ✅ | — | `stock/12` (chia nguyên) cho `full_boxes`, `ceil(stock*1.0/12)` cho `boxes_needed` |
| ex03 | ✅ | — | `timestamptz AT TIME ZONE` → `timestamp` giờ VN |
| ex04 | ✅ | — | `qty::numeric * …` ép trước khi nhân. Câu hỏi phụ đúng ý; chính xác hơn: phép nhân integer **báo lỗi** out of range, cast sau thì đã muộn |
| ex05 | ✅ | — | `amount::numeric = 0.3` đúng nhờ cast float→numeric tự làm tròn 15 chữ số có nghĩa. Nói rõ ý đồ hơn: `round(amount::numeric, 2) = 0.30` |
| ex06 | ✅ | — | `replace(...) ilike '%…%'` là so khớp **chứa**, không phải bằng. Cách đúng bản chất: `external_ref::uuid = '…'::uuid` |
| ex07 | ✅ | — | `is_paid::boolean` gọn, bao được cả `' yes '`, `on`, `1`, `Y`… |
| ex08 | ✅ | — | Nửa mở `'2025-11-11+07'` → `'2025-11-12+07'`, không bọc hàm quanh cột |
| ex09 | ✅ | — | Hiểu đúng chiều `timestamp AT TIME ZONE` → `timestamptz`. Có thể lọc bằng alias? Không — nên lặp biểu thức trong `WHERE` là đúng |
| ex10 | ✅ | 2 · H1 | Lần 1 `round(total/n)`: `bigint / integer` đã cắt phần lẻ **trước** khi `round`, sai 6/12 dòng. Lần 2 `total*1.0/n`. Rõ ý hơn: `total::numeric / n` |

Warm-up 10-12: câu 1 (`AT TIME ZONE` hai chiều) 2.5/3 · câu 2 (literal tháng 9/2026 giờ VN, nửa mở) ✅ nhưng gõ `order.created_at` · câu 3 (`7/2`, `7/2.0`, `7%2`) 2/3, tưởng `7/2` ra numeric.

## 📏 Bonus: UUID lưu bằng `text` vs `uuid` (lab, 1M dòng `gen_random_uuid()`, PK tạo trước rồi INSERT)

Dự đoán: text 36 B, uuid 20 B; bảng tốn thêm ~160 MB ở 10M; index: không biết.

| Đối tượng | `text` | `uuid` | Chênh ở 1M | Ngoại suy 10M |
|---|---|---|---|---|
| 1 giá trị trên đĩa | 37 B | 16 B | 21 B | |
| Bảng | 65.1 MB | 42.2 MB | +22.9 MB | ~+229 MB |
| Index PK | 73.0 MB | 38.4 MB | +34.6 MB | ~+346 MB |

- `uuid` là 16 byte cố định (128 bit), không có header. `text` = 36 ký tự + header varlena: 1 byte khi nằm trên đĩa (37), 4 byte khi là giá trị trong bộ nhớ (40, con số người học đo được bằng hằng số).
- Bảng chênh ~23 B/dòng thay vì 21 B vì mỗi dòng được **căn lề 8 byte** (header 24 B + 37 → 64; 24 + 16 → 40).
- **Index chênh nhiều hơn bảng**: mỗi entry index cũng có header 8 B + khóa, căn lề 8 (48 B so với 24 B); UUID ngẫu nhiên chèn vào giữa index gây page split nên trang chỉ đầy ~70%. Index `text` còn lớn hơn cả bảng.
- Ở 10M dòng: ~575 MB thừa chỉ cho 1 cột + 1 index; chưa tính mọi bảng con có FK trỏ về (cũng phải là `text`) và index trên các FK đó. Ngoài ra so sánh `text` đi qua collation, chậm hơn so sánh 16 byte của `uuid`.

## Nắm chắc
- Không dùng float cho tiền: thấy tận mắt `0.1 + 0.2 = 0.3` là `f` với float, `t` với numeric; `round(float8)` làm tròn về số chẵn.
- `timestamptz` vs `timestamp`, `AT TIME ZONE` hai chiều; literal ISO có múi giờ + nửa mở (ex08, ex09, warm-up câu 2).
- Ép kiểu bằng `::` (numeric, boolean, uuid) để xử lý overflow và dữ liệu bẩn.

## Cần cải thiện
- **Chia số nguyên** (`chia-so-nguyen`): `int / int` cắt phần lẻ trước mọi phép làm tròn phía sau (warm-up câu 3, ex10 lần 1). Thấy dấu `/` thì hỏi: hai vế kiểu gì?
- **Đoán tên** (`doan-ten-cot`): `order.created_at` — bảng là `orders`, và `order` là từ khóa.
- **Viết đúng cái mình muốn nói**: ex05 và ex06 đúng nhờ chi tiết cài đặt/dữ liệu, chưa diễn đạt đúng ý đồ ("làm tròn đến cent", "cùng một UUID").

Lỗi ghi vào weaknesses: `chia-so-nguyen` (mới, ×2), `doan-ten-cot` (+1), `doc-thieu-de` (+1, ex01 ngày 10-09). Streak đúng +1: `literal-thoi-gian`, `dich-de-chinh-xac`.
