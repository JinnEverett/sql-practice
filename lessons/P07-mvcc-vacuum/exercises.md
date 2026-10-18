# P07 · Bài tập (MVCC & VACUUM)

Tất cả chạy trên DB **`lab`** schema `p07` (script chấm tự chạy `setup.sql`, ~4 giây; các bảng tắt autovacuum), riêng ex08 đo trên `shop_s`, `shop_m`.
Cần quyền superuser (VACUUM, `pg_terminate_backend`, extension) nên workspace dùng user `postgres`. Bài làm là SQL trong `answers/exNN.sql`. Tự chấm: `bash tools/check.sh lessons/P07-mvcc-vacuum 02`.
Ex05 dùng một session B chạy nền do script chấm bật (tiến trình `psql` riêng, `application_name = 'p07_report'`).

**Pass:** "Đo & giải thích bloat": 7/8 bài, gồm ex03 và ex08.

---

## 🟢 Cơ bản

### ex01 · Các phiên bản của một dòng
`p07.ver` có 3 dòng; `id = 1` bị UPDATE 3 lần, `id = 3` bị DELETE. Liệt kê mọi tuple trên page 0 bằng `heap_page_items(get_raw_page('p07.ver', 0))`: số slot `lp`, `t_ctid`, đã có `xmax` chưa (`has_xmax`), có cờ `HEAP_HOT_UPDATED` (`t_infomask2 & 16384`) và `HEAP_ONLY_TUPLE` (`& 32768`). Giải thích: bảng chỉ 3 dòng sao page có 6 tuple?
- Cột: `lp, t_ctid, has_xmax, hot_updated, heap_only` · Sắp xếp: `lp`
- Kỳ vọng: **6 dòng**, dòng đầu `1 | (0,4) | t | t | f`

### ex02 · Dọn mà không khóa
`p07.bloat` (100 000 dòng, mỗi dòng bị UPDATE 3 lần) đang có 100 000 dead tuple. Team yêu cầu: dọn dead tuple để chỗ trống được tái sử dụng, **trong lúc bảng vẫn đọc/ghi bình thường (không khóa `ACCESS EXCLUSIVE`)**. File bảng không cần co lại. Sau khi chạy, dead tuple phải bằng 0 và số page của bảng không đổi.

---

## 🟡 Kết hợp

### ex03 · Đo bloat
Với `p07.bloat` ngay sau setup: số page, số tuple sống, số tuple chết (dùng `pgstattuple`) và % lãng phí = 100 − % dung lượng do tuple sống chiếm (`tuple_percent`), làm tròn nguyên.
- Cột: `pages, live, dead, wasted_pct`
- Kỳ vọng: **1 dòng**: `4545 | 100000 | 100000 | 78`

### ex04 · Thu nhỏ file
Team cần trả lại dung lượng đĩa của `p07.bloat`: sau lệnh, số page của heap phải **≤ 40%** (4 545 → ≤ 1 818), vẫn 100 000 dòng và index `bloat_val_idx` còn nguyên. Giờ này bảng không có ai dùng nên chấp nhận khóa. Viết lệnh.

### ex05 · "VACUUM chạy rồi mà dead tuple vẫn còn"
Team báo: sau khi bảng `p07.held` bị UPDATE toàn bảng, `VACUUM p07.held` không dọn được gì. Một báo cáo (`application_name = 'p07_report'`) đã mở transaction `REPEATABLE READ` từ trước. Check dựng đúng tình huống đó: bật B (giữ snapshot ~20 giây), UPDATE toàn bảng, chạy `VACUUM` và xác nhận dead tuple vẫn còn. Viết lệnh **tìm và kết thúc transaction đang giữ** (không đụng vào session khác của hệ thống), sau đó check chạy lại `VACUUM` và kiểm dead tuple = 0.

---

## 🔴 Thực tế

### ex06 · "Bảng lịch sử sắp tới ngưỡng anti-wraparound"
Team báo: bảng lịch sử `p07.hist` (chỉ INSERT, thực tế ~ TB; bài dùng 200 000 dòng) vài tuần nữa sẽ bị autovacuum chạy **bắt buộc** chống wraparound vào giờ cao điểm. Bạn muốn freeze chủ động trong đêm. Viết lệnh để sau khi chạy: mọi page của bảng đều `all_frozen` và `age(relfrozenxid)` còn rất nhỏ (< 1 000). Hỏi thêm: một `VACUUM` thường có đủ không? Vì sao?

### ex07 · "Hàng đợi 20 triệu dòng, autovacuum quá thưa"
Team báo: bảng hàng đợi `p07.queue` thực tế ~ **20 triệu dòng** (bài chỉ có 100 000), liên tục UPDATE trạng thái và DELETE; autovacuum chỉ chạy khi có hơn 4 triệu dead tuple (mặc định `50 + 0.2 × 20 000 000`), bảng phình. Cấu hình **riêng cho bảng** (không đổi toàn server) để autovacuum chạy khi có không quá **150 000** dead tuple (`threshold + scale_factor × 20 000 000`), và bật lại autovacuum cho bảng (bài đang tắt).

---

## 📏 Câu hỏi quy mô

### ex08 · Bloat và VACUUM theo N
Trên bảng tạm sao chép từ `orders` ở `shop_s` (10k) và `shop_m` (1M): **dự đoán** rồi đo: (1) kích thước sau `UPDATE` toàn bảng 1 lần và sau 3 lần liên tiếp (không VACUUM); (2) thời gian `VACUUM`; (3) kích thước sau `UPDATE` thêm lần nữa **sau khi** VACUUM (bảng có tăng nữa không?); (4) thời gian `VACUUM FULL` và kích thước sau; (5) thời gian giữ khóa của `VACUUM FULL` so với `VACUUM`. Dự đoán cho `shop_l` (10M). Đối chiếu `solutions/ex08.md`.
