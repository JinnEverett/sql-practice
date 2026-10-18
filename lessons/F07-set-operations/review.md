# F07 · Review (2026-10-16)

**Điểm: 9/10 · hint: 0 · Pass (≥ 8/10, ≤ 2 hint) ✅**

| Bài | Kết quả | Ghi chú |
|---|---|---|
| ex01 | ✅ | `UNION` đúng, 8 dòng |
| ex02 | ✅ | đếm thẳng từng nguồn bằng `UNION ALL`, không dựng nhật ký `(user_id, ngày, kind)` như đề tả; kết quả y hệt và gọn hơn |
| ex03 | ✅ | `INTERSECT` đúng |
| ex04 | ✅ | `EXCEPT` đúng nhưng dedupe ba lần (`DISTINCT` ×2 + `GROUP BY`), chỉ cần một |
| ex05 | ✅ (nhờ may) | sót "đang bán" (`is_active`), thiếu tiêu chí phụ `id` trong `LIMIT`, dùng `UNION` thay `UNION ALL`. Đúng vì 5 SP đắt/rẻ nhất đều đang bán và 2 SP giá trùng 50000 rơi đúng ngoài top 5 |
| ex06 | ✅ | `EXCEPT` hai chiều đúng. Thừa `JOIN products`, thừa `DISTINCT`, dùng `UNION` thay `UNION ALL` |
| ex07 | ✅ | `GROUP BY … HAVING count(DISTINCT)` rồi `EXCEPT` đúng; không dùng `INTERSECT` nhưng đề không bắt buộc |
| ex08 | ✅ | `count(user_id)` bỏ NULL là mẹo đúng. `DISTINCT` thừa trong mỗi nhánh `UNION` |
| ex09 | ✅ kết quả, ⚠️ yêu cầu | lần 1 đọc lệch "mua hàng" (dùng events thay orders, tổng 977 thay vì 976). Lần 2 đúng kết quả nhưng vẫn dựng bằng `EXISTS`, không dùng `INTERSECT`/`EXCEPT` như đề. Chưa viết lại |
| ex10 | ✅ | `EXCEPT ALL` hai chiều đúng (bẫy `A4` và `A3` NULL). Có `DISTINCT` làm sai nếu dư ≥ 2 bản (thử thêm `A9` ×2: ra 1 dòng thay vì 2) |

## 3 điều nắm chắc
1. `EXCEPT ALL` (multiset) vs `EXCEPT`: tự thấy cần `ALL` để báo bản dư (ex10).
2. `NOT EXISTS`/`EXCEPT` an toàn với NULL; `count(col)` bỏ NULL (ex08).
3. Viết `EXCEPT` hai chiều cho "chỉ ở A" và "chỉ ở B" (ex06, ex10).

## 3 điều cần cải thiện
1. **Dedupe thừa:** `DISTINCT`/`GROUP BY` quanh `UNION`/`INTERSECT`/`EXCEPT` (không `ALL`) là vô nghĩa vì chúng đã bỏ trùng; với `EXCEPT ALL` thì `DISTINCT` còn **đổi nghĩa** (ex10).
2. **`UNION` thay `UNION ALL`:** khi hai vế không thể trùng (nhãn khác nhau) thì `UNION` chỉ tốn sort/hash.
3. **Đọc đề đủ vế:** "đang bán" (ex05), "mua hàng = có đơn" (ex09), "dùng phép tập hợp" (ex09).

## Số đo (`shop_m`, 1 lần đo, chỉ có giá trị xu hướng)
| Bài | bản của bạn | bản tham chiếu |
|---|---|---|
| ex04 | ~1,17 s | ~1,50 s |
| ex06 | ~0,66 s | ~2,14 s |
| ex07 | ~1,61 s | ~0,84 s |
| ex09 | ~1,95 s (`EXISTS`) | ~2,76 s (tập hợp) |

Cả bốn đều quét toàn bảng vì `orders.user_id`, `events.user_id`, `payments.order_id` chưa có index. Chỗ chữa thật là P02, không phải đổi cách viết.

## Còn nợ
- ex09: viết lại bằng `INTERSECT`/`EXCEPT` (tùy chọn).
- Bonus `UNION` vs `UNION ALL` ở quy mô lớn (trong `exercises.md`) chưa làm.
