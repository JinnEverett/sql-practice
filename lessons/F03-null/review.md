# F03 · Review (2026-10-12)

**Kết quả: ✅ đạt, 10/10, 3 hint (H1 ×3).** Đúng ngay lần nộp đầu: 6/10.
Pass theo ROADMAP là 8/10. Mức "≤ 2 hint" ghi trong `exercises.md` bị vượt 1. Vẫn tính ✅ vì cả 10 bài tự viết đúng, không xin đáp án. Đổi lại, buổi ôn +3 ngày tập trung vào `doc-thieu-de`.

| Bài | Kết quả | Số lần nộp | Ghi chú |
|---|---|---|---|
| ex01 | ✅ | 1 | Dự đoán 4/5: đoán `NULL AND false` ra NULL, đúng là `false` |
| ex02 | ✅ | 2 · H1 | Lần 1 `nullif(city, '')` sót trường hợp toàn khoảng trắng (id 11, 22). Lần 2 thêm `btrim` |
| ex03 | ✅ | 1 | `IS DISTINCT FROM`, sửa được lỗi của drill 10-09 |
| ex04 | ✅ | 1 | `DESC NULLS LAST`. Muốn bảo đảm loại hẳn NULL thì thêm `WHERE birth_date IS NOT NULL` |
| ex05 | ✅ | 1 | `count(col)` và `*1.0` đặt trước dấu `/`. Bảng rỗng sẽ lỗi chia cho 0 |
| ex06 | ✅ | 1 | Có đủ `nullif`, `*100.0` và `NULLS LAST`. `ORDER BY` dùng được alias `ctr_pct` |
| ex07 | ✅ | 2 | Lần 1 thiếu làm tròn 2 chữ số. Câu hỏi phụ đúng: không chấm sao ≠ 0 sao |
| ex08 | ✅ | 1 | `IS DISTINCT FROM` + `OR`. Dùng `<>` thì chỉ ra 3/9 dòng. Có thể so cả bộ: `(a, b) IS DISTINCT FROM (c, d)` |
| ex09 | ✅ | 4 · H1 | Mỗi lần nộp chỉ thêm đúng điều kiện vừa bị chỉ ra: 405 → 282 → 273 → 207 dòng. Sót `phone`, `deleted_at`, `country` |
| ex10 | ✅ | 3 · H1 | Lần 1 dùng `<>`, làm mất 85% đơn có code NULL. Thiếu tháng 9: đề viết chưa chặt, đã sửa, không tính lỗi. Người học phản biện cách hiểu đề, phản xạ này tốt |

Warm-up: câu 1 (`1479 / 10000 * 100`) đúng giá trị, sót vế "kiểu gì", vị trí `*1.0` nói chưa rõ · câu 2 (`round` numeric/float8) ✅

## Nắm chắc
- Logic ba trị và `IS DISTINCT FROM`: dùng đúng ngay ở ex03 và ex08, cả hai đều là bẫy kinh điển.
- `COALESCE` / `NULLIF` / `NULLS LAST` / `count(col)` so với `count(*)` / `avg` bỏ qua NULL, và hiểu ý nghĩa nghiệp vụ (ex07).
- Chia số nguyên và literal thời gian: ex05, ex06, ex10 đều đặt ép kiểu và mốc giờ đúng ngay.

## Cần cải thiện
- **Đọc đủ vế đề** (`doc-thieu-de`): 4 lần trong buổi (warm-up câu 1, ex02, ex07, ex09). ex09 là ca nặng nhất: SQL không sai, nhưng 3 điều kiện in đậm bị bỏ qua. Ngoài đời, lỗi này đồng nghĩa với gửi SMS cho người đã xóa tài khoản và cho khách ở nước ngoài.
- **`<>` trên cột có NULL** (`null-so-sanh`): ex03 làm đúng, nhưng ex10 lần đầu vẫn viết `<>` theo phản xạ. Thấy `<>` hoặc `NOT IN` thì tự hỏi: cột này có NULL không?
- **Đề mơ hồ thì hỏi lại hoặc ghi giả định** trước khi nộp, đừng âm thầm chọn một cách hiểu.

Lỗi ghi vào weaknesses: `doc-thieu-de` (+4), `null-so-sanh` (+1). Streak đúng +1: `chia-so-nguyen` (ex05, ex06), `literal-thoi-gian` (ex10).
