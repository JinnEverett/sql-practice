# I03 · Window function I: xếp hạng

Đọc khoảng 9 phút. Ví dụ chạy trên `shop_s`.

## Mục tiêu: sau buổi này bạn làm được
- Hiểu window function khác `GROUP BY` ở đâu: **giữ nguyên từng dòng**, chỉ thêm cột tính trên một "cửa sổ" các dòng liên quan.
- Dùng `row_number`, `rank`, `dense_rank`, `ntile` với `PARTITION BY` và `ORDER BY`.
- Giải bài **top-N mỗi nhóm**, **xóa trùng giữ một bản**, **đơn thứ mấy của khách**.
- Biết window chạy ở bước nào trong thứ tự logic, và vì sao **không lọc được nó trong `WHERE`**.

---

## 1. Cú pháp
```sql
SELECT id, category_id, price,
       row_number() OVER (PARTITION BY category_id ORDER BY price DESC, id) AS rn,
       count(*)     OVER (PARTITION BY category_id)                         AS n_in_cat,
       sum(price)   OVER ()                                                 AS total_all
FROM products
WHERE is_active
ORDER BY category_id, rn
LIMIT 5;
```
- `PARTITION BY`: chia dòng thành nhóm. Mỗi nhóm tính riêng và đánh số lại từ 1. Bỏ trống nghĩa là cả kết quả là một nhóm.
- `ORDER BY` trong `OVER`: thứ tự **bên trong** cửa sổ. Nó không sắp xếp kết quả cuối. Muốn kết quả có thứ tự thì vẫn phải `ORDER BY` ở cuối câu.
- Hàm tổng hợp thường (`count`, `sum`, `avg`…) cũng dùng được với `OVER`. Khác `GROUP BY`: mỗi dòng **vẫn còn**, chỉ được gắn thêm giá trị của nhóm.

## 2. Bốn hàm xếp hạng
Điểm số `100, 90, 90, 80`:

| hàm | kết quả | ghi chú |
|---|---|---|
| `row_number()` | 1, 2, 3, 4 | luôn khác nhau. Hòa thì thứ tự **tùy ý** nếu `ORDER BY` không đủ, vì vậy luôn thêm cột phụ (`id`) |
| `rank()` | 1, 2, 2, **4** | hòa cùng hạng, rồi **nhảy** số |
| `dense_rank()` | 1, 2, 2, **3** | hòa cùng hạng, **không** nhảy |
| `ntile(4)` | 1, 2, 3, 4 | chia thành 4 nhóm **số dòng** gần bằng nhau |

Chọn hàm theo câu hỏi nghiệp vụ:
- "Lấy đúng 3 dòng" → `row_number`.
- "Lấy mọi sản phẩm đồng hạng nhất" → `rank() = 1`.
- "Top 5 mức điểm khác nhau" → `dense_rank() <= 5`.
- "Chia khách thành 4 nhóm đều nhau" → `ntile(4)`.

`percent_rank()` và `cume_dist()` cho thứ hạng dạng tỉ lệ 0–1.

## 3. Thứ tự logic và cách lọc
`FROM → WHERE → GROUP BY → HAVING → window → SELECT → DISTINCT → ORDER BY → LIMIT`
```sql
SELECT * FROM products WHERE row_number() OVER (ORDER BY price) <= 3;
-- ERROR: window functions are not allowed in WHERE

SELECT * FROM (
  SELECT id, price, row_number() OVER (ORDER BY price DESC, id) AS rn FROM products
) t WHERE rn <= 3;                        -- bọc subquery/CTE rồi lọc ở tầng ngoài
```
Hai hệ quả quan trọng:
1. **`WHERE` chạy TRƯỚC window.** Lọc năm 2026 rồi mới đánh số thì "đơn đầu tiên" là đơn đầu tiên **của năm 2026**, không phải của cả lịch sử (ex06). Muốn đánh số trên toàn bộ lịch sử thì đánh số ở tầng trong, lọc ở tầng ngoài.
2. Window chạy **sau `GROUP BY`**, nên dùng được trên giá trị đã gom: `rank() OVER (ORDER BY sum(total_amount) DESC)`.

## 4. Ba mẫu hay dùng
```sql
-- (a) top-N mỗi nhóm
SELECT * FROM (SELECT p.*, row_number() OVER (PARTITION BY category_id ORDER BY price DESC, id) AS rn
               FROM products p) t WHERE rn <= 3;

-- (b) xóa trùng giữ bản sớm nhất (kết hợp F08)
DELETE FROM t WHERE id IN (
  SELECT id FROM (SELECT id, row_number() OVER (PARTITION BY lower(trim(email)) ORDER BY created_at, id) AS rn FROM t) x
  WHERE rn > 1);

-- (c) tỉ trọng trên tổng: window không PARTITION
SELECT status, count(*), round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct
FROM orders GROUP BY status ORDER BY 2 DESC;
```
Postgres còn có `DISTINCT ON (nhóm) … ORDER BY nhóm, tiêu chí` cho trường hợp "1 dòng mỗi nhóm". Cách này gọn nhưng chỉ có ở Postgres.

## Bẫy hay gặp
1. `ORDER BY` trong `OVER` thiếu cột phụ → `row_number` ra thứ tự khác nhau giữa các lần chạy khi có giá trị hòa.
2. Dùng `row_number` khi đề hỏi "tất cả đồng hạng" → mất dòng.
3. Lọc ở cùng tầng với window (ex06).
4. `PARTITION BY` theo cột chưa chuẩn hóa → một nhóm bị tách làm nhiều (ex04).
5. Window trên bảng lớn cần **sort toàn bộ**. Không có index đúng thứ tự thì sort tràn đĩa (ex10).

## Postgres-specific
- MySQL có window function từ 8.0. `DISTINCT ON` và `FILTER` chỉ có ở Postgres.
- Postgres 15+ tối ưu `WHERE rn <= N` ở tầng ngoài (run condition): dừng tính hạng sớm trong mỗi nhóm.
