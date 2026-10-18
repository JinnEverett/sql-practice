# F07 · Bài tập

Bài 1–9 chạy trên **`shop_s`**. Bài 10 chạy trên DB **`lab`**, schema `f07` (đã chạy `setup.sql`; chạy lại được bất cứ lúc nào: `docker exec -i sql-practice-pg psql -U postgres -d lab < lessons/F07-set-operations/setup.sql`).
Mọi mốc thời gian tính theo **UTC**, trừ khi đề ghi "giờ Việt Nam".
Mỗi bài viết vào `answers/exNN.sql` (một câu lệnh), hoặc dán vào chat.
Tự chấm: `bash lessons/check.sh lessons/F07-set-operations 01`.

**Pass:** 8/10 bài, dùng ≤ 2 hint.

> Module này luyện **set operation**. Bài nào ghi "dùng INTERSECT/EXCEPT/UNION ALL" thì phải dùng đúng phép đó, dù cách khác cũng ra cùng kết quả.

---

## 🟢 Cơ bản

### ex01 · Từ điển trạng thái
Hệ thống có hai cột trạng thái: `orders.status` và `payments.status`. Hãy lập **một danh sách duy nhất** mọi giá trị trạng thái đã từng xuất hiện ở **một trong hai** bảng, mỗi giá trị **đúng một lần**.
- Cột: `status`
- Sắp xếp: `status` tăng dần
- Kỳ vọng: **8 dòng**, dòng đầu `cancelled`

### ex02 · Nhật ký hoạt động theo ngày
Gộp hai nguồn thành một "nhật ký": mỗi **đơn hàng** là một dòng loại `'order'`, mỗi **event có đăng nhập** (`user_id` không NULL) là một dòng loại `'event'`. Mỗi dòng gồm `(user_id, ngày, kind)`, trong đó `ngày` là ngày **giờ Việt Nam** của `created_at`.
Sau đó đếm **số dòng** của mỗi loại trong nhật ký. Dùng **UNION ALL** (mỗi dòng gốc phải được đếm đủ).
- Cột: `kind, n_rows`
- Sắp xếp: `kind` tăng dần
- Kỳ vọng: **2 dòng**, dòng đầu có `kind = 'event'`

### ex03 · Khách hàng "hay đổi ý"
Tìm các khách **từng có ít nhất một đơn `delivered` và cũng từng có ít nhất một đơn `refunded`**. Dùng **INTERSECT**.
- Cột: `user_id`
- Sắp xếp: `user_id` tăng dần
- Kỳ vọng: **240 dòng**, dòng đầu `1`

### ex04 · Khách chưa từng trả thành công
Tìm các khách **có đặt đơn** nhưng **chưa từng có giao dịch `succeeded`** nào (trên bất kỳ đơn nào của họ). Dùng **EXCEPT**.
- Cột: `user_id`
- Sắp xếp: `user_id` tăng dần
- Kỳ vọng: **5 dòng**, dòng đầu `623`

---

## 🟡 Kết hợp

### ex05 · Đắt nhất và rẻ nhất
Lập một danh sách **10 dòng** gồm **5 sản phẩm đang bán đắt nhất** (nhóm `'đắt'`) và **5 sản phẩm đang bán rẻ nhất** (nhóm `'rẻ'`). Trong mỗi nhóm, giá trùng thì lấy `id` nhỏ hơn trước. Dùng **UNION ALL**.
- Cột: `nhom, id, name, price`
- Sắp xếp toàn danh sách: `price` giảm dần; trùng thì `id` tăng dần
- Kỳ vọng: **10 dòng**, dòng đầu `đắt | 116 | Laptop Asus C451 | 34311000.00`

### ex06 · Sản phẩm "lên kệ" và "xuống kệ"
Marketing so sánh hai tuần (giờ Việt Nam):
- **Tuần 1:** từ `2026-09-01 00:00` đến trước `2026-09-08 00:00`.
- **Tuần 2:** từ `2026-09-08 00:00` đến trước `2026-09-15 00:00`.

Một sản phẩm "được bán" trong một tuần nếu nó có mặt trong `order_items` của **ít nhất một đơn không bị `cancelled`** đặt trong tuần đó. Liệt kê:
- sản phẩm **chỉ bán ở tuần 1** (không bán ở tuần 2), nhãn `'chỉ tuần 1'`;
- sản phẩm **chỉ bán ở tuần 2**, nhãn `'chỉ tuần 2'`.

Mỗi sản phẩm xuất hiện đúng một lần.
- Cột: `product_id, nhom`
- Sắp xếp: `product_id` tăng dần
- Kỳ vọng: **40 dòng**, dòng đầu `47 | chỉ tuần 2`

### ex07 · Khách bỏ giỏ giữa chừng
Tìm khách (có `user_id`, không tính khách vãng lai) mà trong bảng `events` **vừa có event `add_to_cart` vừa có event `checkout`**, nhưng **chưa từng có đơn hàng nào** trong `orders` (bất kỳ trạng thái nào).
- Cột: `user_id`
- Sắp xếp: `user_id` tăng dần
- Kỳ vọng: **3 dòng**, dòng đầu `467`

### ex08 · Đếm "khách" khi có NULL
Gom mọi giá trị `user_id` xuất hiện ở `events` **hoặc** `orders` (mỗi giá trị một lần, **kể cả NULL** nếu có). Báo cáo 1 dòng gồm:
- `n_tong`: số giá trị khác nhau, **tính cả NULL** như một giá trị;
- `n_co_tai_khoan`: số giá trị khác nhau **không NULL**.

- Cột: `n_tong, n_co_tai_khoan`
- Kỳ vọng: **1 dòng**, `n_tong` hơn `n_co_tai_khoan` đúng **1** đơn vị

---

## 🔴 Thực tế

### ex09 · Phân nhóm khách để gửi chiến dịch
> "Marketing muốn chia **mọi khách chưa bị xóa** (`deleted_at IS NULL`) thành **ba nhóm không giao nhau**, mỗi khách thuộc **đúng một** nhóm, rồi biết mỗi nhóm có bao nhiêu khách:
> - **`mua hàng`**: có ít nhất một đơn (bất kỳ trạng thái);
> - **`chỉ xem`**: **chưa có đơn nào** nhưng có ít nhất một event (qua `user_id`);
> - **`ngủ đông`**: **chưa có đơn nào và không có event nào**."

- Dùng phép tập hợp để dựng ba nhóm (UNION ALL để ghép lại). **Tổng ba nhóm phải bằng đúng số khách chưa bị xóa.**
- Cột: `nhom, n_khach`
- Sắp xếp: `nhom` tăng dần
- Kỳ vọng: **3 dòng**, dòng đầu `chỉ xem | 9`

### ex10 · Đối soát hai bản export tồn kho
> "Kho gửi hai bản export `f07.stock_a` và `f07.stock_b` (cột `sku, warehouse, qty`). Kế toán cần danh sách **mọi dòng khác nhau**, kèm bản nào có dòng đó."

Quy tắc đối soát:
- Hai dòng "giống nhau" nếu giống ở **cả 3 cột**. Hai dòng cùng có `qty` là **NULL** thì **vẫn tính là giống nhau**.
- Một dòng có thể **xuất hiện nhiều lần**. Nếu bản A có dòng đó **2 lần** còn bản B có **1 lần**, thì **1 bản sao dư** ở A vẫn phải được báo là "chỉ A".

- Cột: `nguon, sku, warehouse, qty` (`nguon` là `'chỉ A'` hoặc `'chỉ B'`)
- Sắp xếp: `nguon`, rồi `sku`, rồi `warehouse`
- Kỳ vọng: **5 dòng**, dòng đầu `chỉ A | A2 | HN | 5`

---

## 📏 Bonus (tùy chọn, không tính điểm): `UNION` vs `UNION ALL` ở quy mô lớn
Hai query chỉ khác một từ khóa:
```sql
SELECT count(*) FROM (SELECT user_id FROM events UNION     SELECT user_id FROM orders) t;
SELECT count(*) FROM (SELECT user_id FROM events UNION ALL SELECT user_id FROM orders) t;
```
**Dự đoán trước:** trên `shop_m` (3M events + 1M orders), bản nào nhanh hơn, nhanh hơn khoảng mấy lần, plan khác nhau ở node nào, có tràn đĩa không? Ghi dự đoán vào comment, sau đó đo bằng `EXPLAIN (ANALYZE, BUFFERS)` hoặc `bench`.
