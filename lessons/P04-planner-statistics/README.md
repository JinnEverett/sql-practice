# P04 · Statistics & planner

Đọc khoảng 10 phút. Ví dụ đọc `pg_stats` chạy trên `shop_s` (10 000 đơn, nhỏ hơn mẫu ANALYZE nên thống kê **chính xác và tái hiện được**); các thí nghiệm lệch ước lượng chạy trên `lab.p04` (xem `setup.sql`). Postgres 18.6.

## Mục tiêu: sau buổi này bạn làm được
- Nói được planner biết gì về dữ liệu: `pg_class.reltuples`, `pg_stats` (`n_distinct`, `most_common_vals/freqs`, `histogram_bounds`, `correlation`, `null_frac`).
- Tự tính selectivity và số dòng ước lượng từ `pg_stats`, rồi đối chiếu với `EXPLAIN`.
- Nhận ra ba nguyên nhân ước lượng lệch: **thống kê cũ**, **phân phối lệch vượt khả năng mô tả**, **cột tương quan**; sửa mỗi cái bằng đúng công cụ (`ANALYZE`, `SET STATISTICS`, `CREATE STATISTICS`).
- Đặt lịch tự động ANALYZE hợp lý cho bảng lớn.

---

## 1. Planner biết gì
Planner không nhìn dữ liệu khi lập plan. Nó chỉ có số liệu do `ANALYZE` thu thập (autovacuum tự chạy, hoặc bạn chạy tay):
- `pg_class.reltuples` và số page hiện tại của bảng → số dòng.
- `pg_stats` mỗi cột, tính trên **mẫu** ngẫu nhiên khoảng `300 × default_statistics_target` = **30 000 dòng** (mặc định target 100):
  - `null_frac`, `n_distinct` (âm = tỉ lệ so với số dòng: `-1` là mọi giá trị khác nhau);
  - `most_common_vals` + `most_common_freqs` (MCV, tối đa `target` giá trị phổ biến nhất);
  - `histogram_bounds` (`target`+1 mốc chia phần còn lại thành các thùng bằng số dòng);
  - `correlation` (tương quan giữa thứ tự giá trị và thứ tự vật lý, P03).

Đọc ở `shop_s.orders` (`SELECT … FROM pg_stats WHERE tablename = 'orders'`):

| cột | n_distinct | MCV | histogram | ý nghĩa |
|---|---|---|---|---|
| status | 6 | 6 giá trị, `delivered` 0.8457 | không có | mọi giá trị đều là MCV nên không cần histogram |
| discount_code | 4 | 4, `null_frac` 0.8521 | không có | 85% NULL |
| total_amount | **-0.5564** | 100 | 101 mốc | -0.5564 nghĩa là số giá trị khác nhau ≈ 0.5564 × số dòng (tăng theo bảng) |

## 2. Từ thống kê tới số dòng ước lượng
- `col = giá trị` nằm trong MCV: `rows = reltuples × freq`. `status = 'cancelled'` ở `shop_s`: freq 0.0817 × 10 000 = **817** dòng, đúng bằng `rows=817` trong `EXPLAIN` (thực tế 817).
- Giá trị không trong MCV: lấy phần còn lại chia đều cho các giá trị còn lại: `(1 − tổng freq MCV − null_frac) / (n_distinct − số MCV)`.
- Khoảng (`<`, `BETWEEN`): dùng histogram, nội suy trong thùng.
- `AND` giữa hai điều kiện: **nhân hai selectivity** (giả định độc lập). `OR` thì cộng trừ phần giao.
- `GROUP BY a, b`: số nhóm ước lượng ≈ `n_distinct(a) × n_distinct(b)` (chặn trên bởi số dòng).
- Nối: `|A ⋈ B| = |A| × |B| / max(n_distinct)` ở hai phía khóa.

Sai lệch nhỏ thì vô hại. Sai lệch ≥ 10× đổi cả plan: chọn Nested Loop thay Hash Join, Index Scan thay Seq Scan (hoặc ngược lại), HashAggregate với bộ nhớ không đủ.

## 3. Ba nguồn lệch và cách sửa
**(a) Thống kê cũ.** Sau khi nạp hàng loạt, thống kê chưa biết dữ liệu mới. Đo trên `lab.p04.job`: ANALYZE lúc có 50 000 dòng (3 loại `kind`), rồi chèn 100 000 dòng `kind = 'new'` → `WHERE kind = 'new'` ước lượng **1** dòng, thực tế **100 000** (ex03). Chữa: `ANALYZE bảng`. `VACUUM` thường **không** cập nhật thống kê cột.
Autovacuum ANALYZE khi số dòng đổi `> autovacuum_analyze_threshold (50) + autovacuum_analyze_scale_factor (0.1) × reltuples`: bảng 1M dòng cần **100 050** dòng đổi, bảng 10M cần **1 000 050**. Với bảng lớn, 10% quá thưa. Đặt riêng từng bảng: `ALTER TABLE … SET (autovacuum_analyze_scale_factor = 0.01)`. Dữ liệu tới theo thời gian (log, events) còn có vấn đề "giá trị nằm ngoài histogram": `created_at >= hôm nay` ước lượng 568 dòng trong khi thực tế 20 000 (ex06).

**(b) Phân phối lệch vượt khả năng.** Target 100 chỉ nhớ 100 MCV. Với `p04.tag_event` (3 000 tag, lệch mạnh), tag nằm ngoài top 100 bị ước lượng bằng giá trị trung bình **47** dòng (thực tế 137 với tag 180, tức 2.9×). Chữa: tăng target cho **cột đó**: `ALTER TABLE … ALTER COLUMN tag SET STATISTICS 1000; ANALYZE …` (đo: ước lượng thành 137; tốn thêm thời gian ANALYZE và dung lượng `pg_statistic`). Đừng tăng `default_statistics_target` cho cả server khi chỉ một cột cần.

**(c) Cột tương quan.** `WHERE city = 7 AND zip = 71` trên `p04.addr` ước lượng **21**, thực tế **1 000** (48×), vì `zip` xác định `city` mà planner nhân độc lập. Chữa bằng **extended statistics**:
```sql
CREATE STATISTICS addr_dep (dependencies) ON city, zip FROM p04.addr;   -- phụ thuộc hàm
ANALYZE p04.addr;                                                       -- không ANALYZE thì chưa có số liệu
```
| kiểu | giúp ước lượng |
|---|---|
| `dependencies` | `WHERE a = … AND b = …` khi a xác định b |
| `ndistinct` | số nhóm của `GROUP BY a, b` (ex07) |
| `mcv` | tổ hợp giá trị thường gặp, kể cả khi không phải phụ thuộc hàm |

## 4. Quy trình khi plan tồi
1. `EXPLAIN (ANALYZE, BUFFERS)`; tìm node mà `rows` và `actual rows` lệch ≥ 10×, **node sâu nhất** (lỗi sinh ra ở đó, node trên chỉ thừa hưởng).
2. Phân loại: bảng mới nạp? giá trị hiếm/lệch? hai cột tương quan?
3. Sửa thống kê (không sửa bằng `enable_*`, hint, hay viết lại cho đẹp), rồi `EXPLAIN` lại.
4. Về lâu dài: autovacuum per-table cho bảng lớn, `ANALYZE` ngay sau mỗi lần nạp hàng loạt.

## Bẫy hay gặp
1. `VACUUM` rồi tưởng đã có thống kê mới; `CREATE STATISTICS` mà quên `ANALYZE`.
2. Tăng `default_statistics_target` cho cả server.
3. Xử lý ước lượng lệch bằng `SET enable_nestloop = off`: chỉ che triệu chứng.
4. Tin `pg_stats` của bảng lớn là chính xác: nó từ mẫu 30 000 dòng; `n_distinct` của cột gần-duy-nhất hay bị ước lượng thấp (xem ex08).
5. Quên rằng plan được **cache** trong prepared statement/generic plan dùng thống kê lúc lập.

## Đo bằng gì
- `pg_stats`, `pg_class.reltuples`, `pg_stat_user_tables` (`n_mod_since_analyze`, `last_autoanalyze`), `pg_statistic_ext` và `pg_stats_ext`.
- `EXPLAIN (ANALYZE)`: so `rows` với `actual rows` ở node sâu nhất. Giới hạn của phép đo: `ANALYZE` lấy mẫu ngẫu nhiên nên bảng > 30 000 dòng cho số hơi khác nhau giữa các lần; các bài check dùng ngưỡng rộng.
