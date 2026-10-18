# R02 · Pagination: keyset (cursor)

Đọc khoảng 10 phút. Ví dụ chạy trên `shop_s`; bài tối ưu và câu hỏi quy mô dùng `shop_m`.

## Mục tiêu: sau buổi này bạn làm được
- Giải thích vì sao `OFFSET` sâu chậm tuyến tính và vì sao còn **sai** (lặp/mất dòng) khi dữ liệu thay đổi.
- Viết keyset pagination đúng với sắp xếp nhiều cột, giá trị trùng, NULL và hướng hỗn hợp.
- Làm trang trước / trang sau, và biết khi nào vẫn dùng OFFSET.
- Chọn index để cả lọc lẫn thứ tự được phục vụ bởi một lần dò B-tree, rồi đo bằng `EXPLAIN (ANALYZE, BUFFERS)`.

---

## 1. OFFSET làm gì
```sql
SELECT id, created_at FROM orders ORDER BY created_at DESC, id DESC LIMIT 20 OFFSET 9000;
```
Postgres sinh 9 020 dòng theo thứ tự, bỏ 9 000 dòng đầu, trả 20 dòng. Chi phí ∝ k (số dòng bỏ qua), dù có index. Ở 1M dòng, `OFFSET 900000` mất 190 ms (có index) đến 483 ms (không index) so với 0.1 ms của keyset (ex09).
Lỗi thứ hai là **tính đúng đắn**: khi có đơn mới chèn vào đầu danh sách giữa hai lần tải, mọi dòng bị đẩy xuống một vị trí. Người dùng thấy dòng cuối trang 1 xuất hiện lại ở đầu trang 2. Khi có dòng bị xóa thì họ mất một dòng.

## 2. Keyset: "cho tôi những dòng đứng sau dòng cuối đã xem"
Client giữ **cursor** = giá trị các cột sắp xếp của dòng cuối trang trước.
```sql
SELECT id, created_at FROM orders
WHERE (created_at, id) < ('2026-09-30 09:45:28.287597+00', 9991)
ORDER BY created_at DESC, id DESC
LIMIT 20;
```
- `(a, b) < (x, y)` là **so sánh row-value** theo từ điển: `a < x OR (a = x AND b < y)`. Gọn, đúng, và B-tree dùng được cho một khoảng liên tục.
- Chi phí không phụ thuộc vị trí trang. Dòng mới chèn vào đầu danh sách nằm trước cursor nên không làm lệch trang đang đọc.

## 3. Điều kiện để keyset đúng
1. **Thứ tự phải duy nhất.** `ORDER BY created_at` một mình không đủ khi nhiều dòng trùng giờ: thêm cột duy nhất (`id`) làm tie-breaker, cả ở `ORDER BY` lẫn cursor (ex03).
2. **Điều kiện và ORDER BY cùng hướng.** Row-value `<` đi với `DESC`, `>` đi với `ASC`. Hướng hỗn hợp (`status ASC, created_at DESC`) phải mở rộng thành `OR` (ex05).
3. **NULL.** So sánh với NULL cho kết quả NULL (không true/false). Sắp xếp `NULLS LAST` thì NULL là "lớn nhất": cursor có giá trị phải cộng thêm nhánh `OR col IS NULL`; cursor NULL chỉ còn nhánh `col IS NULL AND id > …` (ex04).
4. **Trang trước:** đảo ORDER BY + đảo dấu so sánh, `LIMIT k`, rồi sắp lại bằng truy vấn ngoài (ex07).
5. **Cursor đưa ra client:** mã hóa (base64 của `ts|id`) và kiểm tra khi nhận lại; đừng nhận SQL fragment từ client. Truyền bằng tham số (prepared statement).

## 4. Index cho keyset
Index cần có: các cột bằng (`WHERE user_id = …`) đứng **trước**, rồi các cột sắp xếp theo đúng thứ tự và hướng (ex08):
```sql
CREATE INDEX ON orders (user_id, created_at DESC, id DESC);
```
Plan mong muốn: một Index Scan dừng sau `LIMIT` dòng, không có node `Sort`, vài chục buffer. Index khác hướng vẫn có thể được quét ngược (backward) khi **toàn bộ** hướng cùng đảo; hướng hỗn hợp thì cần index khai báo đúng hỗn hợp.
Đo bằng gì: `EXPLAIN (ANALYZE, BUFFERS)`: tìm `Sort`, `Rows Removed by Filter`, và `Buffers: shared hit/read`.

## 5. Khi nào vẫn dùng OFFSET
Bảng nhỏ (< vài nghìn dòng), backoffice cần "nhảy tới trang 7", hoặc k bị chặn cứng. Luôn thêm tie-breaker duy nhất vào `ORDER BY`.
Tổng số trang cần `count(*)` tốn O(N). Với bảng lớn, bỏ "trang x/y": chỉ trả `has_next` bằng cách lấy `LIMIT k + 1` rồi bỏ dòng thừa.

## Bẫy hay gặp
1. `WHERE created_at < :cursor` (thiếu tie-breaker) → mất dòng trùng giờ; `<=` → lặp dòng.
2. Sắp xếp giảm dần nhưng quên đổi dấu so sánh (dùng `>`).
3. Cột sắp xếp nullable mà quên nhánh NULL → trang cuối bị cắt.
4. Row-value với hướng hỗn hợp: `(status, created_at, id) > (…)` coi cả ba cùng tăng.
5. Cursor lấy từ `OFFSET`-style `page=…` trong URL: vẫn bị lệch khi dữ liệu thay đổi.

## Postgres-specific
- Row-value comparison (`ROW(a, b) < ROW(x, y)`) là chuẩn SQL và Postgres dùng được B-tree cho dạng này (kiểm bằng EXPLAIN: `Index Cond: (ROW(created_at, id) < ROW(…))`). Không cần viết `OR` thủ công trừ khi hướng sắp xếp hỗn hợp.
- `NULLS FIRST/LAST` mặc định: ASC → NULL cuối, DESC → NULL **đầu**. Hãy viết tường minh.
