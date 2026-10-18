# F05 · Review (2026-10-12 → 2026-10-13)

**Kết quả: ✅ đạt, 10/10, 0 hint.** Học qua 2 buổi: ex01–ex06 làm ngày 2026-10-12, được chấm lại ngày 2026-10-13 (đều ✅, không ghi lại số lần nộp); ex07–ex10 làm ngày 2026-10-13.

| Bài | Kết quả | Số lần nộp | Ghi chú |
|---|---|---|---|
| ex01 | ✅ | ? | INNER JOIN 2 bảng, alias đúng |
| ex02 | ✅ | ? | Nối 4 bảng, `quantity*unit_price` |
| ex03 | ✅ | ? | Anti join bằng `LEFT JOIN … WHERE o.id IS NULL` |
| ex04 | ✅ | ? | `count(o.id)` sau LEFT JOIN; điều kiện bảng trái (`country`) ở `WHERE` |
| ex05 | ✅ | ? | Self join + `coalesce(…, '(gốc)')` |
| ex06 | ✅ | ? | Literal `'2026-09-01 +07'` nửa mở, lọc `delivered` |
| ex07 | ✅ | 1 | Đặt điều kiện bảng phải ở `ON`, bảng trái ở `WHERE`: đúng bẫy chính của LEFT JOIN. Alias `u.id as id` thừa |
| ex08 | ✅ | 2 | Lần 1 sót **đã giao** (316 thay vì 192). Khử trùng bằng `GROUP BY 1,2,3`, nên dùng `DISTINCT` hoặc `EXISTS` (F06) |
| ex09 | ✅ | 1 | Bài 🔴. `u1.id < u2.id` loại cả tự ghép lẫn cặp đảo. Thiếu tiêu chí phụ `u2.id` |
| ex10 | ✅ | 2 | Lần 1: fan-out items × payments (đơn 1688 cộng 5 lần), INNER JOIN mất đơn 1686, `sum FILTER` ra NULL, `>= 1684`. Lần 2: gộp `order_items` trước khi JOIN, `coalesce`, LEFT JOIN: đúng |

Warm-up (ngày 2026-10-13): câu 1 `NOT IN (1,2,NULL)` ✅ · câu 2 `date_trunc` theo giờ VN ✅ sau H1 + H2 (hiểu nhầm rằng `timestamptz` lưu kèm "+7").
Bonus ex03: người học hỏi đáp án, coach giải thích kèm số đo trên `shop_m` (205 ms, quét hết 1M đơn; `WHERE o.id IS NULL` không thành anti join, `o.user_id IS NULL` thì thành `Hash Right Anti Join`, 137 ms).

## Nắm chắc
- `ON` và `WHERE` với LEFT JOIN (ex04, ex07 đúng ngay).
- Self join tìm cặp, `a.id < b.id` (ex09 🔴 đúng ngay).
- Gộp trước, JOIN sau để chữa fan-out (ex10 tự sửa sau khi được chỉ ra cơ chế).

## Cần cải thiện
- **Đọc đủ điều kiện in đậm** (`doc-thieu-de`, +2): ex08 sót "đã giao", ex10 viết `1684` thay vì `1685` và vẫn ra 10 dòng nhờ trùng hợp.
- **Nhận ra fan-out trước khi viết**: khi JOIN 2 bảng "nhiều" vào cùng một bảng cha, hãy tự hỏi "mỗi dòng kết quả là cái gì?".
- **`timestamptz` không lưu múi giờ**: chỉ là một thời điểm. Múi giờ chỉ xuất hiện khi hiển thị hoặc khi `date_trunc`/`extract`.

Lỗi ghi vào weaknesses: `doc-thieu-de` (+2), `join-fanout` (mới, 1), `literal-thoi-gian` (+1, warm-up). Streak đúng: `null-so-sanh` (warm-up), `doan-ten-cot` (hỏi nghĩa cột thay vì đoán, dùng đúng bảng `payments`).
