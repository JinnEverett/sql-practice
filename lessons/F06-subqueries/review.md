# F06 · Subqueries · Review

**Điểm: 10/10 · hint: 0 · ngày: 2026-10-15** (ex01–ex05 viết 2026-10-13, chấm 2026-10-15)

| Bài | Kết quả | Ghi chú |
|---|---|---|
| ex01–ex05 | ✅ lần đầu | scalar subquery, `IN`, `EXISTS`, `NOT EXISTS`; khớp `checks` |
| ex06 | ✅ lần 3 | lần 1 correlate theo `brand`; lần 2 sửa `WHERE` mà sót `SELECT`, thiếu `round` |
| ex07 | ✅ lần 1 | danh mục lá + count đúng, giữ danh mục 0 sản phẩm |
| ex08 | ✅ lần 1 | `avg` của tổng theo khách |
| ex09 | ✅ lần 2 | lần 1 sót "đã giao" (223 thay vì 203) |
| ex10 | ✅ lần 2 | lần 1 `= 'delivered'` thay vì loại `cancelled`, `refunded` (1 dòng thay vì 62) |

## 3 điều nắm chắc
1. Correlated subquery, scalar subquery trong `SELECT`, `NOT EXISTS` an toàn với NULL (ex05, ex07, ex09).
2. Đọc "trung bình của tổng theo nhóm" đúng (ex08), `coalesce` cho tổng của tập rỗng (ex10).
3. Literal thời gian có `+07`, khoảng nửa mở: đúng ở ex04, ex09, ex10.

## 3 điều cần cải thiện
1. Sót hoặc đọc lệch vế đề (ex06, ex09, ex10). Với mỗi cụm in đậm của đề, nói trước nó thành điều kiện gì.
2. Khi đề nói "có tồn tại" thì dùng `EXISTS`, không dùng `JOIN` + `GROUP BY` để khử trùng lặp (ex09).
3. Subquery correlate chạy lại cho từng dòng: cần nghĩ tới index hoặc gộp trước (ex06, ex10). Xem số đo bên dưới.

## Số đo (EXPLAIN ANALYZE)
- ex06: `shop_m`, 20 000 sản phẩm: ~10,5 triệu buffer hit, mỗi dòng quét lại cả `products`.
- ex07: `shop_m`: subquery `count` 37,5 ms, 11 152 buffer; gộp trước rồi `LEFT JOIN`: 3,7 ms, 406 buffer.
- ex09: `shop_m`, 1 lần đo cache lạnh: `JOIN` + `GROUP BY` ~274 ms; `EXISTS` ~129 ms.
- ex10: `payments` chỉ có index `payments_pkey`, mỗi subquery quét ~1,04 triệu dòng, 118 471 đơn tháng 9 trên `shop_m`; chạy quá 2 phút không xong, hủy tay. Bọc subquery trong bảng dẫn xuất không đổi plan (planner tự gộp lại).

## Lỗi đã ghi vào weaknesses
`doc-thieu-de` (+3), `dich-de-chinh-xac` (+1), `inner-join-mat-dong` (từ drill).
