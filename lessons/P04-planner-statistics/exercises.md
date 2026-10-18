# P04 · Bài tập (Statistics & planner)

Bài 1–2 chạy trên **`shop_s`** (10 000 đơn, mẫu ANALYZE phủ toàn bảng nên số liệu cố định); bài 3–7 trên DB **`lab`** schema `p04` (script chấm tự chạy `setup.sql`, các bảng tắt autovacuum); bài 8 đo trên `shop_s`, `shop_m`.
Bài 3–7 là bài **sửa plan**: bài làm là các lệnh (ANALYZE, ALTER, CREATE STATISTICS…) trong `answers/exNN.sql`; query lỗi cho sẵn trong đề. Check chạy lệnh của bạn rồi chạy `EXPLAIN (ANALYZE)` (không parallel) và kiểm **ước lượng so với thực tế** với ngưỡng rộng. Tự chấm: `bash tools/check.sh lessons/P04-planner-statistics 03`.
Với mỗi bài, ghi lại plan trước và sau (`rows` vs `actual rows`).

**Pass:** "Sửa 3 plan sai do stats": 6/8 bài, gồm ít nhất 3 trong ex03–ex07.

---

## 🟢 Cơ bản

### ex01 · Đọc pg_stats
`shop_s.orders`, các cột `status`, `discount_code`, `total_amount`: từ `pg_stats` lấy `n_distinct` (làm tròn 3 chữ số), `null_frac` (3 chữ số), số giá trị MCV (0 nếu không có), số mốc histogram (0 nếu không có). Giải thích: vì sao `total_amount` có `n_distinct` âm? vì sao `status` không có histogram?
- Cột: `attname, n_distinct, null_frac, n_mcv, n_hist_bounds` · Sắp xếp: `attname`
- Kỳ vọng: **3 dòng**, dòng đầu `discount_code | 4.000 | 0.852 | 4 | 0`

### ex02 · Tự tính số dòng ước lượng
`shop_s.orders`: cho mỗi giá trị `status`, tính số dòng planner ước lượng cho `WHERE status = giá_trị` từ `pg_class.reltuples` và `most_common_freqs` (làm tròn nguyên), kèm số dòng thực tế. Đối chiếu một giá trị với `EXPLAIN`.
- Cột: `status, est_rows, actual_rows` · Sắp xếp: `status`
- Kỳ vọng: **6 dòng**, dòng đầu `cancelled | 817 | 817`

---

## 🟡 Kết hợp

### ex03 · Mới nạp xong
`lab.p04.job`: ANALYZE lúc 50 000 dòng (`kind` ∈ a/b/c), sau đó nạp thêm 100 000 dòng `kind = 'new'`. Query `SELECT * FROM p04.job WHERE kind = 'new'` ước lượng 1 dòng, thực tế 100 000. Sửa để ước lượng sai **không quá 3×**.

### ex04 · Tag lệch
`lab.p04.tag_event` (200 000 dòng, 3 000 tag, phân phối lệch mạnh). Query `SELECT * FROM p04.tag_event WHERE tag = 180` ước lượng 47 dòng, thực tế 137. Sửa sao cho ước lượng sai **không quá 1.5×**, chỉ thay đổi thống kê của cột `tag` (không đổi cấu hình toàn server).

### ex05 · Thành phố và mã bưu điện
`lab.p04.addr` (100 000 dòng; mỗi `city` có đúng 2 `zip`, mỗi `zip` thuộc đúng một `city`). Query `SELECT * FROM p04.addr WHERE city = 7 AND zip = 71` ước lượng ~21, thực tế 1 000. Sửa để ước lượng sai **không quá 2×**.

---

## 🔴 Thực tế

### ex06 · "Báo cáo sáng nào cũng chậm"
Team báo: job nạp `p04.log` hằng đêm thêm ~20 000 dòng; sáng nào `SELECT * FROM p04.log WHERE created_at >= '2026-10-01'` (thực tế 20 000 dòng) cũng chậm tới khi ai đó chạy ANALYZE tay. Hiện ước lượng 568 dòng. Sửa ngay để ước lượng sai **không quá 3×**, **và** cấu hình bảng để về lâu dài autovacuum tự ANALYZE khi có ≥ 1% dòng đổi (bảng đang tắt autovacuum cho bài tập: bật lại). Mặc định (10%) cần 22 050 dòng đổi mới ANALYZE, nhiều hơn 20 000 của job đêm.

### ex07 · "Báo cáo GROUP BY dùng quá nhiều RAM"
Team báo: `SELECT a, b, count(*) FROM p04.fact GROUP BY a, b` dự kiến ~20 000 nhóm (thực tế 1 000, vì `b` luôn bằng `a`), RAM dự trù cho HashAggregate gấp 5 lần cần thiết và sẽ tràn đĩa khi bảng lớn hơn. Sửa để số nhóm ước lượng sai **không quá 2×**.

---

## 📏 Câu hỏi quy mô

### ex08 · ANALYZE ở 10k, 1M, 10M
**Dự đoán trước** (ghi ra): `ANALYZE orders` chạy bao lâu ở `shop_s` (10k), `shop_m` (1M), `shop_l` (10M)? Mẫu ANALYZE là 30 000 dòng cố định, vậy thời gian có tăng ×100 khi N tăng ×100 không? Với `orders.user_id` (ở `m` có 99 040 giá trị khác nhau), `n_distinct` mà ANALYZE ước lượng sai bao nhiêu? Và ở N = 1M, 10M autovacuum chờ bao nhiêu dòng thay đổi mới ANALYZE? Đo bằng `\timing` + `pg_stats`; đối chiếu `solutions/ex08.md`.
