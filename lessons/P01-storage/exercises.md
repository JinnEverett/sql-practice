# P01 · Bài tập (Storage)

Bài 1, 2, 8 chạy trên **`shop_s`**; bài 3–7 trên DB **`lab`** schema `p01` (script chấm tự chạy `setup.sql`); bài 9 đo trên `shop_s` và `shop_m`.
Mỗi bài một câu lệnh (hoặc một cụm DDL) vào `answers/exNN.sql`. Tự chấm: `bash tools/check.sh lessons/P01-storage 01`.
Cần `pageinspect`: `setup.sql` tự tạo trên `lab`; với `shop_s` chạy `CREATE EXTENSION IF NOT EXISTS pageinspect;` trước.

**Pass:** "Giải thích được bằng số liệu thật": 7/9 bài và phải làm ex09.

---

## 🟢 Cơ bản

### ex01 · Một bảng chiếm bao nhiêu?
Bảng `orders` (`shop_s`): số page, số dòng, số dòng trung bình mỗi page (1 chữ số thập phân) và số byte trung bình mỗi dòng (làm tròn số nguyên). Chỉ tính **heap** (không index, không TOAST). Dùng `block_size` thật của server, không gõ cứng 8192.
- Cột: `n_pages, n_rows, rows_per_page, bytes_per_row`
- Kỳ vọng: **1 dòng**: `120 | 10000 | 83.3 | 98`

### ex02 · Dòng nằm ở đâu?
Với 5 đơn có `id` nhỏ nhất của `orders` (`shop_s`): tách `ctid` thành số page và số slot (cả hai là số nguyên).
- Cột: `id, page_no, slot_no` · Sắp xếp: `id`
- Kỳ vọng: **5 dòng**, dòng đầu `1 | 0 | 1`

### ex03 · Bao nhiêu byte thật sự được lưu?
Bảng `lab.p01.docs`. Theo từng `kind`: độ dài gốc trung bình (`avg_len`, byte), số byte lưu trữ trung bình (`avg_stored`) và số dòng đã bị nén (`n_compressed`). Làm tròn trung bình về số nguyên.
- Cột: `kind, avg_len, avg_stored, n_compressed` · Sắp xếp: `avg_len`
- Kỳ vọng: **3 dòng**, dòng đầu `short | 96 | 97 | 0`

---

## 🟡 Kết hợp

### ex04 · Heap và TOAST
Với `lab.p01.docs`: số page của heap, số page của bảng TOAST đi kèm, và phần trăm TOAST trong tổng (heap + TOAST), 1 chữ số thập phân.
- Cột: `heap_pages, toast_pages, toast_pct` · 1 dòng
- Kỳ vọng: **1 dòng**: `14 | 2300 | 99.4`

### ex05 · Đếm mà không kéo TOAST
Đếm số tài liệu trong `lab.p01.docs` có `body` dài hơn 50 000 byte. Câu trả lời phải là **một SELECT trả về 1 số** và đọc ít hơn 200 buffers (heap chỉ 14 page; đọc cả TOAST là hơn 2 000).
- Cột: `n` · Kỳ vọng: **1 dòng**: `300`
- Chấm bằng `EXPLAIN (ANALYZE, BUFFERS)`: kiểm số buffers, không kiểm chuỗi SQL.

### ex06 · Xếp lại cột
`lab.p01.pad_bad(a boolean, b bigint, c boolean, d bigint, e boolean, f smallint)` có 50 000 dòng và chiếm 417 page. Viết `CREATE TABLE lab.p01.pad_good` **cùng 6 cột, cùng kiểu**, nhưng đặt thứ tự sao cho cùng dữ liệu chiếm **≤ 85%** dung lượng `pad_bad`. Check sẽ nạp dữ liệu từ `pad_bad` vào bảng của bạn theo tên cột.

---

## 🔴 Thực tế

### ex07 · "Bộ đếm cứ phình ra"
Team báo: bảng `lab.p01.counters` (2 000 dòng, `fillfactor` 100, có index trên `label`) chạy job `UPDATE counters SET hits = hits + 1 WHERE id % 10 = 0` mỗi vài giây; index `counters_label_idx` ngày càng chậm và file bảng cứ tăng, dù không ai đổi `label`. Bạn xác định nguyên nhân là UPDATE hầu như không phải HOT vì page đầy. Viết các lệnh DDL (không `UPDATE` dữ liệu, không xóa index) để sau khi chạy xong, job trên đạt **≥ 90% HOT** (180/200 phiên bản mới là heap-only tuple). Giữ nguyên index `counters_label_idx` và số dòng.
- Check chạy DDL của bạn rồi chạy job và đếm tuple có cờ `HEAP_ONLY_TUPLE` bằng `pageinspect`. Không kiểm chuỗi SQL.

### ex08 · Dự toán dung lượng
Team dự toán "mỗi dòng khoảng 100 byte". Trên `shop_s`, cho từng bảng `orders`, `order_items`, `payments`, `events`: số dòng, số page của heap, byte trung bình mỗi dòng **kể cả overhead** (làm tròn số nguyên). Heap thôi, không index.
- Cột: `table_name, n_rows, heap_pages, bytes_per_row` · Sắp xếp: `table_name`
- Kỳ vọng: **4 dòng**, dòng đầu `events | 32363 | 452 | 114`

---

## 📏 Câu hỏi quy mô

### ex09 · Dự đoán dung lượng ở 1M và 10M
Từ số đo `bytes_per_row` của ex08 trên `shop_s`, **dự đoán** (ghi lại trước khi chạy) dung lượng heap của `orders` và `events` ở `shop_m` (N = 1M) và `shop_l` (N = 10M). Sau đó đo `shop_m` bằng `pg_relation_size`; `shop_l` nếu máy bạn đã sinh. Câu trả lời tự đối chiếu với `solutions/ex09.md`. Trả lời thêm: sai lệch (nếu có) đến từ đâu?
