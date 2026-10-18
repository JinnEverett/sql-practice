# R06 · Bài tập (Dữ liệu cây)

Bài 1, 2 chạy trên **`shop_s`** (bảng `categories`); bài 3–8 trên DB **`lab`** schema `r06` (script chấm tự chạy `setup.sql`: bảng `cat` (adjacency), `cat_lt` (adjacency + ltree), `cat_closure` (rỗng), `cat_closure_ready`, `cat_ns` (nested set), `prod`); bài 9 là câu hỏi quy mô (tự đối chiếu).
Cây danh mục có 8 gốc và 42 nút; ví dụ nhánh `2 Điện tử → 16 Âm thanh → 34 Tai nghe`. Sản phẩm `r06.prod(id, category_id)` gắn vào các danh mục từ tầng 2 trở xuống.
Tự chấm: `bash tools/check.sh lessons/R06-hierarchical-data 01`.

**Pass:** 6/8 (8 bài chấm tự động + ex09 tự đối chiếu số đo). Yêu cầu của ROADMAP "So sánh 3 cách" được đáp ứng bằng ex05/06/07 (closure, ltree, nested set) và ex09.

---

## 🟢 Cơ bản

### ex01 · Cây con bằng recursive CTE
Trên `shop_s`, liệt kê mọi danh mục nằm dưới danh mục `id = 2` (không gồm chính nó), kèm độ sâu so với nút 2 (con trực tiếp có `depth = 1`).
- Cột: `id, name, depth` · Sắp xếp: `depth`, `id`
- Kỳ vọng: **8 dòng**, dòng đầu `13 | Điện thoại | 1`

### ex02 · Breadcrumb
Trên `shop_s`, với mỗi danh mục tạo đường dẫn từ gốc, nối bằng `' > '` (vd. `Điện tử > Âm thanh > Tai nghe`), và độ sâu (gốc = 0).
- Cột: `id, breadcrumb, depth` · Sắp xếp: `id`
- Kỳ vọng: **42 dòng**, dòng đầu `1 | Thời trang | 0`

---

## 🟡 Kết hợp

### ex03 · Dựng path ltree
Bảng `r06.cat` có cột `path ltree` đang trống. Điền `path` cho cả cây, dùng **id** làm nhãn (nút 34 có path `2.16.34`, nút gốc 2 có path `2`).
- Kiểm tra: trạng thái bảng `r06.cat` sau khi chạy (`id, parent_id, path`)

### ex04 · Dựng closure table
Điền `r06.cat_closure(ancestor, descendant, depth)` với mọi cặp tổ tiên–hậu duệ **gồm cả cặp tự thân** `(n, n, 0)`, từ cây trong `r06.cat`.
- Kiểm tra: trạng thái bảng (89 dòng)

### ex05 · Thống kê theo danh mục gốc
Dùng `r06.cat_closure_ready` (đã dựng sẵn, có cặp tự thân), cho mỗi danh mục gốc: số danh mục trong cây con (gồm chính nó) và số sản phẩm (`r06.prod`) trong cây con. Danh mục gốc không có sản phẩm nào vẫn phải hiện với số 0.
- Cột: `root_id, root_name, n_categories, n_products` · Sắp xếp: `root_id`
- Kỳ vọng: **8 dòng**, dòng đầu `1 | Thời trang | 9 | 33`

---

## 🔴 Thực tế

### ex06 · "Chuyển Âm thanh sang Nhà cửa" (ltree)
Team catalog báo: danh mục `16 Âm thanh` (đang thuộc `2 Điện tử`) cần chuyển sang thuộc `3 Nhà cửa & Đời sống`. Bảng `r06.cat_lt` có cả `parent_id` và `path ltree` (path đã được điền). Chuyển nút 16 **cùng cây con của nó** (34 Tai nghe, 35 Loa) sao cho `parent_id` và `path` của mọi nút liên quan đều đúng. Các nút khác không đổi.
- Kiểm tra: trạng thái bảng `r06.cat_lt` (`id, parent_id, path`); nút 34 phải có path `3.16.34`

### ex07 · Tổ tiên và quy mô (nested set)
Bảng `r06.cat_ns(id, name, lft, rgt)` lưu cây theo nested set. Liệt kê các tổ tiên của nút `34` (không gồm chính nó), từ gốc xuống, kèm số hậu duệ của mỗi tổ tiên. Tính số hậu duệ thẳng từ `lft`, `rgt`, không đếm.
- Cột: `id, name, n_descendants` · Sắp xếp: `lft`
- Kỳ vọng: **2 dòng**, dòng đầu `2 | Điện tử | 8`

### ex08 · Chặn chu trình
Trên `r06.cat`, hiện không gì ngăn việc đặt `parent_id` của một nút là chính nó hoặc hậu duệ của nó (tạo chu trình làm recursive CTE chạy vô hạn). Viết trigger `BEFORE INSERT OR UPDATE OF parent_id` báo lỗi `check_violation` (SQLSTATE `23514`) khi nút bị đặt làm con của chính nó hoặc của một hậu duệ của nó; các thao tác hợp lệ (chuyển sang cha khác, thành gốc, thêm nút mới, đổi tên) vẫn chạy.
- Kiểm tra bằng bộ test

---

## 📏 ex09 · Câu hỏi quy mô: bốn cách biểu diễn cây ở 11k → 1.1M nút
Cây đều, mỗi nút 10 con. Ba thao tác: (Q1) đếm cây con của một nút tầng 2, (Q2) lấy tổ tiên của một lá, (Q3) di chuyển cây con đó sang cha khác.
1. **Dự đoán** (ghi vào `answers/ex09.md`): với mỗi cách (adjacency + recursive CTE, ltree, closure, nested set) và mỗi thao tác, chi phí tăng thế nào khi N tăng 100 lần (11k → 1.1M)? Cách nào ghi nhiều dòng nhất khi di chuyển? Cách nào có Q2 chậm nhất?
2. Tự dựng bốn bảng (xem `solutions/ex09.sql`, đổi tham số 5 thành 6 hoặc 7) và đo bằng `EXPLAIN (ANALYZE)`.
3. Giải thích điểm gãy và chọn cách cho: (a) danh mục sản phẩm (ít đổi, đọc nhiều), (b) cây bình luận (thêm liên tục, hiếm di chuyển), (c) org chart (di chuyển cả phòng ban thường xuyên).

Lời giải và số đo thật: `solutions/ex09.md`.
