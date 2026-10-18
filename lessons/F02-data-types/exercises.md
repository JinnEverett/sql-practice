# F02 · Bài tập

Mỗi bài ghi rõ chạy trên **DB nào**: `shop_s` (dữ liệu chung) hoặc `lab` (bảng riêng của bài, trong schema `f02`). Vào DB `lab` bằng `\c lab`.
Mọi mốc thời gian tính theo **UTC**, trừ khi đề ghi "giờ Việt Nam".
Mỗi bài viết vào `answers/exNN.sql` (một câu `SELECT`), hoặc dán vào chat.
Tự chấm: `bash lessons/check.sh lessons/F02-data-types 01`

> **Đọc hết đề trước khi nộp**: thiếu một vế (cột, điều kiện, sắp xếp, câu hỏi phụ) là một lần nộp sai. Điểm yếu `doc-thieu-de` (×7) và `dich-de-chinh-xac` (×4).
> Mốc thời gian: luôn viết ISO kèm múi giờ (`'2025-11-11 00:00+07'`), dùng nửa mở `>= … <`, không dùng `BETWEEN`.

**Pass:** 8/10 bài, dùng ≤ 2 hint.

Bảng trong `lab.f02` (xem bằng `\d f02.*`):

| Bảng | Mô tả |
|---|---|
| `f02.legacy_wallet` | Ví điện tử cũ, lưu tiền tip USD bằng `double precision` |
| `f02.b2b_lines` | Dòng hàng đơn sỉ, `qty` và `unit_price_vnd` đều là `integer` |
| `f02.partners` | Đối tác, mã tham chiếu UUID lưu bằng `text`, mỗi nguồn ghi một kiểu |
| `f02.legacy_orders` | Đơn từ máy POS cũ: `created_local` là **giờ Việt Nam** lưu bằng `timestamp`, `is_paid` là `text` |
| `f02.installment_plans` | Kế hoạch trả góp: tổng tiền `bigint` (VND), chia thành `n` kỳ |

---

## 🟢 Cơ bản

### ex01 · 0.1 + 0.2 · DB `lab`
Viết **một** câu `SELECT` không cần bảng, trả về 1 dòng:
- `float_sum`: 0.1 + 0.2, tính bằng `double precision`
- `numeric_sum`: 0.1 + 0.2, tính bằng `numeric`
- `float_eq`: tổng kiểu float có bằng 0.3 (cũng kiểu float) không
- `numeric_eq`: tổng kiểu numeric có bằng 0.3 không
- Kỳ vọng: `0.30000000000000004 | 0.3 | f | t`
- Trả lời thêm trong chat: *nếu bạn thiết kế bảng `payments`, cột `amount` nên dùng kiểu gì, và vì sao?*

### ex02 · Đóng thùng · DB `shop_s`
Mỗi thùng chứa **12** sản phẩm. Với các sản phẩm có `id` từ 1 đến 10, tính:
- `full_boxes`: số thùng **đầy**
- `remainder`: số sản phẩm lẻ còn lại sau khi đóng các thùng đầy
- `boxes_needed`: số thùng cần dùng để đóng **hết** hàng (thùng cuối có thể không đầy)
- Cột: `id, stock, full_boxes, remainder, boxes_needed`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **10 dòng**, dòng đầu `1 | 325 | 27 | 1 | 28`

### ex03 · Giờ Việt Nam · DB `shop_s`
CSKH đọc giờ đặt hàng theo giờ Việt Nam. Với 5 đơn có `id` từ 1 đến 5, hiển thị giờ gốc và giờ Việt Nam.
- Cột: `id, created_at, created_at_vn`. Cột `created_at_vn` có kiểu `timestamp` (không có đuôi múi giờ)
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **5 dòng**, dòng đầu `1 | 2024-02-17 05:46:43.25737+00 | 2024-02-17 12:46:43.25737`

### ex04 · Đơn sỉ bị lỗi · DB `lab`
Tính thành tiền của từng dòng hàng trong `f02.b2b_lines`: `line_total = qty × unit_price_vnd`.
- Cột: `id, qty, unit_price_vnd, line_total`
- Sắp xếp: `line_total` giảm dần; bằng nhau thì `id` tăng dần
- Kỳ vọng: **30 dòng**, dòng đầu `17 | 4970 | 1400000 | 6958000000`
- Thử viết cách đơn giản nhất trước để xem có chuyện gì. Sửa xong, trả lời thêm trong chat: *vì sao viết `(qty * unit_price_vnd)::bigint` vẫn lỗi?*

---

## 🟡 Kết hợp

### ex05 · Tip đúng 0.3 USD · DB `lab`
Bộ phận tài chính hỏi: "Có những giao dịch tip nào **đúng 0.30 USD**?" Dữ liệu nằm trong `f02.legacy_wallet`.
- Cột: `id, amount`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **30 dòng**

### ex06 · Một đối tác, nhiều cách ghi · DB `lab`
Ứng dụng gửi lên mã đối tác `a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11`. Tìm **mọi** dòng trong `f02.partners` có mã tham chiếu là UUID này, bất kể nó được ghi theo định dạng nào.
- Cột: `id, name, external_ref`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **3 dòng**
- Trả lời thêm trong chat: *nếu cột `external_ref` có kiểu `uuid` ngay từ đầu, bài này sẽ đơn giản hơn thế nào? Kể ra ít nhất 2 lợi ích khác của việc dùng kiểu `uuid` thay vì `text`.*

### ex07 · Đơn POS đã thanh toán · DB `lab`
Liệt kê các đơn trong `f02.legacy_orders` **đã thanh toán**. Cột `is_paid` được các phiên bản POS ghi theo nhiều kiểu khác nhau. Hãy `SELECT DISTINCT is_paid` để xem trước.
- Cột: `id, is_paid, total_vnd`
- Sắp xếp: `id` tăng dần
- Kỳ vọng: **63 dòng**

---

## 🔴 Thực tế

### ex08 · Ngày sale 11/11 · DB `shop_s`
> "Marketing cần danh sách các đơn **từ 5 triệu trở lên** đặt trong ngày sale **11/11/2025, tính theo giờ Việt Nam**, để gửi voucher cảm ơn. Bên mình đọc giờ Việt Nam nên cột giờ cũng hiển thị giờ Việt Nam luôn nhé."

- Cột: `id, created_at_vn, total_amount`
- Sắp xếp: đặt sớm trước; trùng thì `id` tăng dần
- Kỳ vọng: **20 dòng**

### ex09 · Ghép dữ liệu POS vào báo cáo năm · DB `lab`
> "Báo cáo tài chính năm 2025 tính theo **UTC**, giống hệ thống mới. Hãy lấy các đơn POS cũ thuộc năm 2025 **theo UTC**, kèm một cột thời điểm chuẩn `timestamptz` để ghép với bảng `orders`. Nhớ là máy POS ghi giờ Việt Nam."

- Cột: `id, created_local, created_at`. Cột `created_at` có kiểu `timestamptz`, là thời điểm thật của đơn
- Sắp xếp: `created_at` tăng dần; trùng thì `id` tăng dần
- Kỳ vọng: **117 dòng**

### ex10 · Chia tiền trả góp · DB `lab`
> "Mỗi kế hoạch trong `f02.installment_plans` chia tổng tiền thành `n` kỳ. Các kỳ đầu bằng nhau, bằng `total / n` **làm tròn đến đồng** (0,5 thì làm tròn lên). **Kỳ cuối** gánh phần chênh lệch, sao cho tổng các kỳ **khớp đúng** `total`, không dư không thiếu một đồng."

- Cột: `order_id, total, n, per_installment, last_installment`
- Sắp xếp: `order_id` tăng dần
- Kỳ vọng: **12 dòng**, dòng đầu `1 | 100000 | 3 | 33333 | 33334`

---

## 📏 Bonus (tùy chọn, không tính điểm): kiểu dữ liệu ở quy mô lớn
Bảng `orders` của một shop lớn có **10 triệu dòng**. Giả sử khóa chính là UUID nhưng lưu bằng `text` thay vì `uuid`.

**Dự đoán trước khi đo**, viết dưới dạng comment vào `answers/bonus.sql`:
1. Riêng cột khóa chính, bảng tốn thêm khoảng bao nhiêu MB?
2. Index của khóa chính tốn thêm khoảng bao nhiêu MB?

Sau đó đo bằng `pg_column_size(...)`, rồi tạo thử bảng 1M dòng trong `lab` để kiểm chứng.
