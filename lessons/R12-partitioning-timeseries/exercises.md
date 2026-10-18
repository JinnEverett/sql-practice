# R12 · Bài tập (Partitioning & time-series)

Tất cả chạy trên **DB `lab`** schema `r12` (script chấm tự chạy `setup.sql`: `events_p` partition theo tháng UTC từ 2026-01 đến 2026-06 với 60 000 dòng; `legacy_events` 5 000 dòng tháng 7; `metrics_raw` và `metrics_daily`).
Bài 1, 3, 4 viết DDL tạo bảng (bộ chấm chạy rồi ROLLBACK); bài 2 là một câu SELECT chấm cả kết quả lẫn plan; bài 5, 7 chấm bằng trạng thái bảng; bài 6, 8 chấm bằng bộ test.
Dùng ranh giới UTC tường minh (`'…+00'`). Tự chấm: `bash tools/check.sh lessons/R12-partitioning-timeseries 01`. Bài 9 là câu hỏi quy mô (tự đối chiếu).

**Pass:** ROADMAP "Partition + pruning hoạt động" = ex01 + ex02 + ex05 đúng; tổng 6/8.

---

## 🟢 Cơ bản

### ex01 · Bảng partition theo tháng
Tạo `r12.readings(device_id int, ts timestamptz, value numeric(10,2))`, partition `RANGE (ts)`, với các partition `readings_2026_01`, `readings_2026_02`, `readings_2026_03` (mỗi tháng UTC) và `readings_default` hứng phần còn lại. Khóa chính `(device_id, ts)`.
- Kiểm tra bằng bộ test (định tuyến dòng, ranh giới nửa mở, PK)

### ex02 · Truy vấn cắt tỉa được partition
Với `r12.events_p`, đếm số event và giá trị trung bình (làm tròn 2 chữ số) trong **tháng 3/2026 theo giờ Việt Nam**. Kết quả phải đúng và plan chỉ được quét các partition thật sự cần (không quét cả 6).
- Cột: `n_events, avg_value`
- Kiểm tra bằng bộ test (so kết quả với tham chiếu, kiểm tra plan không chạy mà chỉ `EXPLAIN`)

---

## 🟡 Kết hợp

### ex03 · Partition theo danh sách
Tạo `r12.orders_by_region(order_id bigint, region text, amount numeric(12,2))` partition `LIST (region)`: `orders_north` (`'north'`), `orders_south` (`'south'`), `orders_other` (default). Khóa chính hợp lệ cho bảng partition.
- Kiểm tra bằng bộ test (kể cả hệ quả với tính duy nhất của `order_id`)

### ex04 · Partition theo hash
Tạo `r12.tenant_logs(tenant_id int, id bigint, msg text)` chia thành 4 partition `tenant_logs_0..3` bằng `HASH (tenant_id)`, khóa chính `(tenant_id, id)`. Dữ liệu của 200 tenant phải phân bố khá đều, và truy vấn theo một `tenant_id` chỉ chạm 1 partition.
- Kiểm tra bằng bộ test

---

## 🔴 Thực tế

### ex05 · "Chỉ giữ 3 tháng dữ liệu"
Chính sách mới: `r12.events_p` chỉ giữ 3 tháng gần nhất (04, 05, 06/2026). Xóa dữ liệu tháng 1–3 sao cho không sinh dead tuple, không cần VACUUM, và không để lại bảng cũ nào (cả partition lẫn bảng đã tách).
- Kiểm tra: danh sách bảng `events_p_2026_*` còn lại và tổng số dòng

### ex06 · "Gắn bảng tháng 7 vào events_p mà không khóa lâu"
`r12.legacy_events` (5 000 dòng, đủ cột và PK `(id, ts)`) chứa toàn bộ dữ liệu tháng 7/2026 và vẫn đang được ghi. Biến nó thành partition tháng 7 của `r12.events_p` mà **không bắt Postgres quét lại cả bảng dưới khóa mạnh**: chuẩn bị bảng để `ATTACH PARTITION` biết ngay mọi dòng nằm trong khoảng, và không để lại ràng buộc thừa.
- Kiểm tra bằng bộ test (bảng đã là partition, đủ 5000 dòng, chèn được tháng 7 qua bảng cha, và lúc ATTACH bảng đã có CHECK được xác thực)

### ex07 · Rollup theo ngày, chạy lại được
`r12.metrics_raw(sensor, ts, value)` lưu mỗi giờ một số đo. Tính lại `r12.metrics_daily(sensor, day, n, sum_value, min_value, max_value)` cho các ngày 01–03/03/2026 (ngày theo giờ Việt Nam; khoảng `[2026-03-01 00:00+07, 2026-03-04 00:00+07)`) bằng **một câu** sao cho: ngày chưa có thì chèn, ngày đã có thì ghi đè (dòng `sensor 1, 2026-03-02` đang sai), và chạy lại bao nhiêu lần cũng cho cùng kết quả.
- Kiểm tra: trạng thái bảng `metrics_daily` (6 dòng)

### ex08 · Tạo partition tháng tới
Viết hàm `r12.ensure_month(p_day date) RETURNS text`: tạo partition của `r12.events_p` cho tháng chứa `p_day` (tên `events_p_YYYY_MM`, khoảng UTC `[ngày 1 tháng này, ngày 1 tháng sau)`), trả về tên partition; gọi lại cho cùng tháng không được lỗi. Đúng cả với tháng 12.
- Kiểm tra bằng bộ test

---

## 📏 ex09 · Câu hỏi quy mô: partition có làm nhanh hơn không?
Bảng `ev(id, device, ts, value)`, 1M và 5M dòng trải đều 1 năm. So bảng thường và bảng partition 12 tháng với: truy vấn một ngày; truy vấn một tháng; retention một tháng; và với số partition 12 / 365 / 1 460 thì thời gian lập kế hoạch ra sao.
1. **Dự đoán** (ghi vào `answers/ex09.md`): (a) khi KHÔNG có index trên `ts`, partition nhanh hơn bao nhiêu lần (theo số buffer)? (b) khi CÓ index trên `ts`, partition có nhanh hơn không? (c) planning time với 1 460 partition so với bảng thường? (d) `DELETE` một tháng và `DETACH + DROP` sinh bao nhiêu WAL?
2. Tự đo (`solutions/ex09.sql` là bản nhỏ; tăng N lên 1M/5M), dùng `EXPLAIN (ANALYZE, BUFFERS)` và chênh lệch `pg_current_wal_lsn()`.
3. Giải thích điểm gãy và khi nào KHÔNG nên partition.

Lời giải và số đo thật: `solutions/ex09.md`.
