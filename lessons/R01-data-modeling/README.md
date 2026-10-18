# R01 · Data modeling

Đọc khoảng 10 phút. Ví dụ chạy trên `shop_s` và schema `lab.r01` (tạo bởi `setup.sql`).

## Mục tiêu: sau buổi này bạn làm được
- Vẽ ERD và nhận ra vi phạm 1NF / 2NF / 3NF từ dữ liệu thật bằng query (không chỉ bằng mắt).
- Tách một bảng "phẳng" thành các bảng chuẩn hóa, có PK / FK / UNIQUE / CHECK đúng.
- Quyết định **khi nào denormalize** và ép tính nhất quán bằng ràng buộc hoặc query kiểm tra.
- Chọn khóa tự nhiên hay surrogate; đặt tên nhất quán; nhớ rằng FK **không tự có index**.

---

## 1. Chuẩn hóa là gì, bằng ví dụ
Chuẩn hóa = mỗi sự thật được lưu **đúng một chỗ**. Cách kiểm tra là *phụ thuộc hàm* (functional dependency, FD): `A → B` nghĩa là mỗi giá trị của `A` ứng với đúng một giá trị của `B`.

| Dạng | Quy tắc | Vi phạm thường gặp |
|---|---|---|
| 1NF | mỗi ô một giá trị nguyên tử, không lặp nhóm cột | `items = 'BUT:10,VO:5'`, cột `phone1, phone2, phone3` |
| 2NF | mọi cột không khóa phụ thuộc **toàn bộ** khóa ghép | `order_lines(order_id, sku, product_name)`: `product_name` chỉ phụ thuộc `sku` |
| 3NF | cột không khóa không phụ thuộc vào cột không khóa khác | `orders(customer_id, customer_city)`: `customer_id → customer_city` |
| BCNF | mọi định thức (vế trái của FD) là siêu khóa | hiếm gặp; xuất hiện khi có nhiều khóa ứng viên chồng nhau |

Cách phát hiện bằng SQL: nếu `A → B` đúng thì `count(DISTINCT B)` theo từng `A` luôn ≤ 1.

```sql
SELECT customer_id, count(DISTINCT customer_city) AS n
FROM r01.flat_sales GROUP BY customer_id HAVING count(DISTINCT customer_city) > 1;
```
Kết quả có dòng nghĩa là FD bị vi phạm: **update anomaly** đã xảy ra (đổi địa chỉ ở một dòng mà quên các dòng khác).

## 2. Ba loại anomaly mà chuẩn hóa chặn
- **Update:** đổi tên sản phẩm phải sửa N dòng; sửa thiếu thì dữ liệu mâu thuẫn.
- **Insert:** muốn thêm khách mới nhưng bảng phẳng chỉ có thể có khách khi đã có đơn.
- **Delete:** xóa đơn cuối cùng của khách → mất luôn thông tin khách.

## 3. Khi nào denormalize
Chuẩn hóa là mặc định. Denormalize khi bạn **chọn có ý thức** và trả giá để giữ nhất quán:
1. **Snapshot lịch sử.** `order_items.unit_price` lặp lại thông tin giá, nhưng nó là giá *lúc mua*. Bản sao này không bao giờ cần đồng bộ lại. Nếu join sang `products.price` thì doanh thu quá khứ đổi mỗi khi đổi giá (ex07).
2. **Dữ liệu dẫn xuất đọc nhiều.** `orders.total_amount` = tổng các dòng + phí ship − giảm giá. Đọc nhanh, nhưng phải có cơ chế đảm bảo đúng (trigger, ghi trong cùng transaction, hoặc query đối soát định kỳ như ex08). Ở `shop_*`, 0.2% đơn đã lệch.
3. **Số đếm / tổng hợp** (`posts.comment_count`): nhanh khi đọc, nhưng thành điểm nghẽn ghi (hot row, xem R08/D06).
Không denormalize chỉ vì "join chậm": join có index trên vài triệu dòng là việc Postgres làm tốt (P03, P10).

## 4. Khóa: tự nhiên hay surrogate
| | Surrogate (`bigint GENERATED … AS IDENTITY`, `uuid`) | Tự nhiên (email, mã ISO, SKU) |
|---|---|---|
| Ổn định khi dữ liệu đổi | ✅ | ❌ (đổi email → phải sửa mọi FK) |
| Nhỏ, join nhanh | ✅ (8 byte) | tùy |
| Chống trùng nghiệp vụ | ❌ cần thêm `UNIQUE` | ✅ |
Thực hành: bảng giao dịch dùng surrogate **và** vẫn khai báo `UNIQUE` trên khóa tự nhiên (`users.email` ở `shop_*` thì không, và đó là nguồn của dữ liệu trùng ở R03). Bảng tra cứu nhỏ và bất biến (mã quốc gia ISO) dùng khóa tự nhiên được.
`UNIQUE` coi NULL là **khác nhau**: `UNIQUE (product_id, region)` cho phép nhiều dòng `(1, NULL)`. Postgres 15+ có `UNIQUE NULLS NOT DISTINCT` (ex04).

## 5. Quy ước đặt tên (chọn một và giữ nguyên)
- Bảng số nhiều, `snake_case` (`order_items`); cột khóa ngoại `<bảng_số_ít>_id` (`customer_id`).
- Boolean bắt đầu bằng `is_`/`has_`; thời điểm kết thúc bằng `_at` (`timestamptz`), ngày bằng `_on`/`_date`.
- Không dùng từ khóa (`user`, `order`) làm tên bảng mà không nháy kép: `shop_*` dùng `users` và `orders` là vì vậy.
- Tên constraint/index có ý nghĩa (`user_phones_primary_uq`) để thông báo lỗi dễ đọc.

## 6. Bẫy hay gặp
1. **FK không có index** → xóa/sửa bảng cha là Seq Scan bảng con, JOIN chậm (ex10: 230 ms → 5 ms ở 1M dòng).
2. **Cột đa trị trong một ô** (`'BUT:10,VO:5'`, mảng/jsonb dùng bừa): không FK, không ràng buộc, không thống kê.
3. **`varchar(n)`/`float` cho tiền**: dùng `numeric(12,2)`; không đặt giới hạn độ dài tùy tiện (`text` + `CHECK` khi có quy tắc thật).
4. **Quên ràng buộc vì "app đã kiểm tra rồi"**: app có nhiều service, có script, có người chạy tay. Ràng buộc ở database là hàng rào cuối cùng.
5. **Enum cứng**: `CHECK (status IN (…))` dễ đổi hơn kiểu `ENUM` (thêm giá trị thì được, bớt giá trị thì không).

## Postgres-specific
- Từ Postgres 12, thay đổi `CHECK`/`NOT NULL` có cách làm không khóa lâu (R10). Từ 15: `NULLS NOT DISTINCT`. `GENERATED ALWAYS AS IDENTITY` thay `serial`.
- Không có index tự động cho FK (MySQL/InnoDB thì có).
