# I02 · Bài tập

Bài 1–4 chạy trên **`shop_s`**. Bài 5–8 chạy trên DB **`lab`**, schema `i02` (script chấm tự chạy lại `setup.sql`; thử tay thì chạy `setup.sql` trước).
Mỗi bài viết **một câu lệnh** dùng `WITH RECURSIVE` vào `answers/exNN.sql`. Tự chấm: `bash tools/check.sh lessons/I02-recursive-cte 01`.

**Pass:** 6/8 bài. Bài 9 là câu hỏi quy mô (tự đối chiếu).

---

## 🟢 Cơ bản

### ex01 · Lịch đơn hàng tháng 9
Dùng CTE đệ quy (chưa dùng `generate_series`) sinh **mọi ngày** từ `2026-09-01` đến `2026-09-30`. Mỗi ngày cho biết số đơn đặt trong ngày đó (**ngày giờ VN**); ngày không có đơn thì ghi 0.
- Cột: `ngay` (kiểu `date`), `n_orders`
- Sắp xếp: `ngay` tăng dần
- Kỳ vọng: **30 dòng**, dòng đầu `2026-09-01 | 30`

### ex02 · Cây danh mục Điện tử
Liệt kê danh mục `'Điện tử'` và **mọi danh mục con cháu** của nó. `depth` = 0 với Điện tử, 1 với con, 2 với cháu. `path` là chuỗi tên từ gốc xuống, ngăn bởi `' > '`, ví dụ `Điện tử > Âm thanh > Loa`.
- Cột: `id, name, depth, path`
- Sắp xếp: `path` tăng dần
- Kỳ vọng: **9 dòng**, dòng đầu `2 | Điện tử | 0 | Điện tử`

### ex03 · Breadcrumb sản phẩm
Với các sản phẩm `id ≤ 5`, dựng breadcrumb danh mục **từ gốc tới danh mục của sản phẩm**, ví dụ `Điện tử > Phụ kiện điện tử > Ốp lưng`. Sản phẩm có thể nằm ở tầng 2 hoặc tầng 3 của cây.
- Cột: `product_id, breadcrumb`
- Sắp xếp: `product_id` tăng dần
- Kỳ vọng: **5 dòng**, dòng đầu `1 | Điện tử > Phụ kiện điện tử > Ốp lưng`

### ex04 · Doanh thu theo ngành hàng gốc
Doanh thu dòng hàng = `quantity × unit_price`, chỉ tính đơn `delivered`. Gom doanh thu về **8 danh mục gốc** (không có cha). Sản phẩm ở tầng nào cũng phải được tính về đúng gốc của nó.
- Cột: `root_name, revenue`
- Sắp xếp: `revenue` giảm dần
- Kỳ vọng: **8 dòng**, dòng đầu `Điện tử | 37834326000.00`

---

## 🟡 Kết hợp

### ex05 · Quy mô từng team
DB `lab`, bảng `i02.employees(id, full_name, title, manager_id)`. Với mỗi người **có ít nhất một cấp dưới**, cho biết số cấp dưới **trực tiếp** (`n_direct`) và **tổng số người dưới quyền** gồm cả gián tiếp, ở mọi tầng (`n_total`). Không tính bản thân.
- Cột: `id, full_name, n_direct, n_total`
- Sắp xếp: `n_total` giảm dần, trùng thì `id` tăng dần
- Kỳ vọng: **7 dòng**, dòng đầu `1 | Minh | 3 | 14`

### ex06 · Dữ liệu nhập tay có vòng lặp
`i02.emp_import(id, full_name, manager_id)` được nhập từ Excel và bị lỗi: có người là "quản lý của quản lý của… chính mình". Tìm `id` của **những người nằm trên một vòng** quản lý. Người chỉ **trỏ vào** một vòng (mà bản thân không nằm trên vòng) thì không tính. Query phải **dừng** được, không chạy vô hạn.
- Cột: `id`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **4 dòng**, dòng đầu `20`

---

## 🔴 Thực tế

### ex07 · Vé máy bay rẻ nhất SGN → HAN
`i02.flights(src, dst, price)` là các chuyến bay **một chiều**. Khách muốn bay từ `SGN` đến `HAN` với **tối đa 2 lần nối chuyến** (tối đa 3 chặng), không đi qua cùng một sân bay hai lần. Đưa ra **3 hành trình rẻ nhất**.
- Cột: `route` (dạng `SGN→DAD→HAN`, mũi tên `→`), `legs` (số chặng), `total_price`
- Sắp xếp: `total_price` tăng dần, trùng thì `route` tăng dần
- Kỳ vọng: **3 dòng**, dòng đầu `SGN→DAD→HAN | 2 | 1300000`

### ex08 · Đặt linh kiện cho 10 laptop
`i02.bom(parent, child, qty)` là định mức vật tư: làm **1** `parent` cần `qty` cái `child`. Một linh kiện con có thể lại được lắp từ các linh kiện nhỏ hơn. Xưởng cần lắp **10 chiếc `Laptop`**. Hãy tính tổng số lượng cần mua của từng **linh kiện cơ bản** (linh kiện không được lắp từ thứ gì khác). Linh kiện xuất hiện ở nhiều nhánh thì cộng dồn.
- Cột: `part, total_qty`
- Sắp xếp: `part` tăng dần
- Kỳ vọng: **7 dòng**; `Ốc vít` cần **240**

---

## 📏 ex09 · Câu hỏi quy mô: đệ quy trên cây 10 triệu nút
Dựng cây N nút, mỗi nút có 10 con, rồi tìm mọi con cháu của nút 1234:
```sql
CREATE TABLE i02_tree AS SELECT g AS id, CASE WHEN g = 1 THEN NULL ELSE (g + 8) / 10 END AS parent_id
FROM generate_series(1, 1000000) g;                -- thử N = 10 000, 1 000 000, 10 000 000
ALTER TABLE i02_tree ADD PRIMARY KEY (id);
ANALYZE i02_tree;
EXPLAIN (ANALYZE, BUFFERS)
WITH RECURSIVE d AS (SELECT id FROM i02_tree WHERE id = 1234
  UNION ALL SELECT t.id FROM i02_tree t JOIN d ON t.parent_id = d.id)
SELECT count(*) FROM d;
-- sau đó: CREATE INDEX ON i02_tree (parent_id); ANALYZE i02_tree; rồi chạy lại EXPLAIN
```
1. **Dự đoán trước** (ghi vào `answers/ex09.md`): với mỗi N, có và không có index trên `parent_id`, query mất bao lâu? Kết quả chỉ có vài chục đến vài nghìn dòng: thời gian phụ thuộc vào cái gì?
2. Chạy thử, ghi lại thời gian và buffers. Dọn bảng: `DROP TABLE i02_tree;`
3. Giải thích điểm gãy. Lời giải và số đo thật: `solutions/ex09.md`.
