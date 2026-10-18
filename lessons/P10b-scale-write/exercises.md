# P10b · Bài tập (Hiệu ứng quy mô: ghi & vận hành)

Chạy trên DB **`lab`**. `bash tools/check.sh` tự chạy `setup.sql` (schema `p10b`, ~3 giây). Bài đo ở 1M/10M dùng bảng của P10a (`p10.t_m`; `p10l.t_l` từ `lessons/P10a-scale-read/setup-large.sql`). Bài đo tạo bảng tạm trong schema `p10b` (setup xóa chúng).
**Quy tắc:** mỗi thí nghiệm **ghi dự đoán ra trước**, rồi đo. Pass: dự đoán đúng xu hướng ≥ 70% số ô và giải thích được mọi điểm gãy bằng số đo. Bài 3, 4, 7, 8 tự chấm (`bash tools/check.sh lessons/P10b-scale-write 03`); bài 1, 2, 5, 6 là thí nghiệm tự đối chiếu với `solutions/exNN.md`.
Bài 4 và 7 dùng session phụ ở nền: một writer chèn một dòng mỗi 0.1 giây (autocommit) vào bảng đích trong lúc DDL của bạn chạy, và check đo **khoảng lặng lớn nhất** của writer. Bảng có 5 000 dòng và hàm `slow_id`/`slow_ok` (~1 ms mỗi lần gọi) làm thao tác quét kéo dài ~5.7 giây.

**Pass:** 7/8 bài, mỗi bài đo có dự đoán trước.

---

## 📏 Ghi

### ex01 · Từng dòng, theo lô, COPY
**Dự đoán:** nạp 100 000 dòng (7 cột, PK) bằng (a) 100 000 câu `INSERT` autocommit, (b) 100 câu `INSERT … VALUES` 1 000 dòng, (c) `INSERT … SELECT`, (d) `COPY`: thời gian và WAL của từng cách, chênh nhau bao nhiêu lần? Đo, đối chiếu `solutions/ex01.md`.

### ex02 · Mỗi index thêm bao nhiêu
**Dự đoán:** `INSERT … SELECT` 1M dòng vào bảng chỉ có PK, rồi có thêm 1, 3, 5 index: thời gian, WAL, dung lượng index. Đo, đối chiếu `solutions/ex02.md`.

### ex03 · Nạp mà không tiêu xid (tự chấm)
`p10b.src` (5 000 dòng) → `p10b.dst` (cùng 3 cột). Viết script nạp toàn bộ sao cho **tiêu ≤ 50 xid** (cách "từng dòng" tiêu ≥ 5 000). Giải thích: vì sao xid quan trọng (P07, wraparound)?

---

## 🟡 Vận hành

### ex04 · Xây index trên bảng đang bị ghi (tự chấm)
`p10b.t4` đang nhận ghi liên tục. Tạo index trên biểu thức `p10b.slow_id(id)` (mất ~5.7 giây) sao cho khoảng lặng lớn nhất của writer **< 1 giây**, và index cuối cùng `indisvalid`. Bài làm là lệnh tạo index (check chạy ngoài transaction).

### ex05 · ALTER TABLE: tức thì hay rewrite
**Dự đoán** thời gian (và có giữ khóa lâu không) ở `t_s`, `t_m`, `t_l` cho: `ADD COLUMN x int`; `ADD COLUMN x int DEFAULT 0`; `ADD COLUMN x double precision DEFAULT random()`; `ALTER COLUMN amount TYPE bigint`; `ADD CONSTRAINT CHECK (amount >= 0)`; cùng ràng buộc `NOT VALID` rồi `VALIDATE`; `SET NOT NULL`; và `CREATE INDEX` thường so với `CONCURRENTLY`. Đo trong `BEGIN … ROLLBACK`. Đối chiếu `solutions/ex05.md`.

### ex06 · UPDATE hàng loạt, VACUUM, ANALYZE, dung lượng
**Dự đoán** ở `t_s`, `t_m`, `t_l`: kích thước sau `UPDATE` toàn bảng một câu; thời gian `VACUUM` và `ANALYZE`; peak dung lượng khi UPDATE theo 10 lô và `VACUUM` sau mỗi lô; dung lượng heap + index + TOAST theo N. Đo, đối chiếu `solutions/ex06.md`.

---

## 🔴 Thực tế

### ex07 · Thêm CHECK lên bảng lớn (tự chấm)
Team báo: lần trước `ALTER TABLE … ADD CONSTRAINT … CHECK` trên bảng lớn làm site đứng vì quét bảng dưới khóa chặn cả `SELECT`. Thêm `CHECK (p10b.slow_ok(id))` lên `p10b.t7` (quét mất ~5.7 giây) sao cho khoảng lặng lớn nhất của writer **< 1 giây** và ràng buộc cuối cùng `convalidated`.

### ex08 · Backfill 100 000 dòng không giữ transaction lớn (tự chấm)
Thêm cột `amount_big bigint` vào `p10b.big` (100 000 dòng) và đặt `amount_big = amount` cho mọi dòng, nhưng **không bằng một câu UPDATE duy nhất**: mỗi transaction chỉ được sửa một lô (check đòi ≥ 6 transaction, ≤ 2 000, và dữ liệu đúng). Giải thích 3 lý do không nên làm một câu.
