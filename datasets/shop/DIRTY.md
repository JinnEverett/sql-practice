# ⚠️ SPOILER: dữ liệu bẩn cài sẵn

> Dành cho Claude khi ra đề. Người học nên tự phát hiện trong các bài F03, F08, R03, R07 và sql-case trước khi đọc file này.

Số liệu đo trên `shop_m` (N = 1M):

| Lỗi | Tỉ lệ | Số lượng (m) | Bài khai thác |
|---|---|---|---|
| Email trùng khi so không phân biệt hoa/thường và bỏ khoảng trắng (`UPPER`, thêm space đầu/cuối, `initcap`) | 0.5% user | 500 | F06, R03, case dọn dữ liệu |
| `orders.total_amount` ≠ `sum(items) + shipping_fee - discount_amount` | 0.2% đơn | 1 995 | F05, case đối soát |
| Trừ tiền 2 lần: 2 payment `succeeded` cho cùng 1 đơn, cách nhau 3 giây | 0.1% đơn đã trả tiền | 893 | R03, D04 |
| Đơn tạo trước ngày user đăng ký | rất ít | 145 | case chất lượng dữ liệu |
| Đơn `pending` treo hơn 30 ngày | 0.3% | 2 681 | case vận hành |
| `city` ghi kiểu khác cho TP.HCM: `TP.HCM`, `Ho Chi Minh`, `HCM` | ~1% user | 1 034 | F10, I06 |
| `phone` có 2 định dạng: `09xxxxxxxx` và `+84 9xxxxxxxx` | 2% user | | I06 |
| Event thiếu key `device` trong jsonb | 1% event | 32 669 | I07 |
| Tên sản phẩm thừa khoảng trắng cuối | 0.5% sản phẩm | 82 | F10 |
| Từ khóa tìm kiếm có dấu và không dấu (`áo thun` / `ao thun`) | | | R11 (unaccent) |
| `unit_price` khác `products.price` hiện tại | 10% dòng hàng | | F05 (giá lúc mua ≠ giá hiện tại) |
| Sản phẩm giá 0 (quà tặng) | 0.3% | | F04 (chia cho 0, avg) |
| NULL: `full_name` 2%, `city` 5%, `phone` 30%, `birth_date` 40%, `discount_code` 85%, `events.user_id` 30% | | | F03 |
| Đơn của user đã bị soft delete (`deleted_at` không NULL) | | | R05 |
