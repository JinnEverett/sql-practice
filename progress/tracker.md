# Tracker

Trạng thái: ⬜ chưa học · 🟡 đang học · ✅ đạt · 🔁 cần ôn lại

## Hồ sơ người học
- Trình độ khởi điểm: chưa biết SQL (2026-10-07). Không làm placement test, đi từ F01
- Mục tiêu: backend / phỏng vấn. Trọng số cao cho Tier P, R, D; Tier O chỉ cần nắm khái niệm (O01, O03, O04, O06 là chính)
- Thời lượng mỗi buổi: 60–90 phút
- Tần suất: hằng ngày. Dự kiến khoảng 75 buổi (gồm cả drill/case xen kẽ), tức khoảng 2,5–3 tháng
- Máy: ổ C còn khoảng 33GB trống (90% đã dùng), ổ D còn 143GB. Docker giữ mặc định trên ổ C (người học chọn). Trước khi sinh `shop_l` (~9GB) phải kiểm tra lại dung lượng trống ổ C
- Client: psql (PowerShell) + DBeaver 26.1 (cài ở `%LOCALAPPDATA%\DBeaver`). DBeaver lỗi `TimeZone "Asia/Saigon"` vì update ghi đè `dbeaver.ini`; phương án bền là cài `tzdata-legacy` vào image (chưa làm)

## Dataset đã sinh

| DB | N (orders) | Dung lượng | Ngày sinh |
|---|---|---|---|
| shop_xs | 100 | 9 MB | 2026-10-07 |
| shop_s | 10 000 | 18 MB | 2026-10-07 |
| shop_m | 1 000 000 | 908 MB | 2026-10-07 |
| shop_l | | | |
| shop_xl | | | |

## Module

| ID | Trạng thái | Điểm | Hint dùng | Ngày | Ôn lại lúc |
|---|---|---|---|---|---|
| S00 | ✅ | 4/5 | 0 | 2026-10-07 | 2026-10-10 |
| F01 | ✅ | 9/10 | 0 | 2026-10-08 | 2026-10-11 |
| F02 | ✅ | 10/10 | 1 | 2026-10-12 | 2026-10-22 |
| F03 | ✅ | 10/10 | 3 | 2026-10-12 | 2026-10-22 |
| F04 | 🔁 | 10/10 | 0 | 2026-10-12 | 2026-10-18 |
| F05 | ✅ | 10/10 | 0 | 2026-10-13 | 2026-10-16 |
| F06 | ✅ | 10/10 | 0 | 2026-10-15 | 2026-10-18 |
| F07 | ✅ | 9/10 | 0 | 2026-10-16 | 2026-10-19 |
| F08 | 🟡 | | | 2026-10-16 | |
| F09 | ⬜ | | | | |
| F10 | ⬜ | | | | |
| I01 | ⬜ | | | | |
| I02 | ⬜ | | | | |
| I03 | ⬜ | | | | |
| I04 | ⬜ | | | | |
| I05 | ⬜ | | | | |
| I06 | ⬜ | | | | |
| I07 | ⬜ | | | | |
| I08 | ⬜ | | | | |
| I09 | ⬜ | | | | |
| P01 | ⬜ | | | | |
| P02 | ⬜ | | | | |
| P03 | ⬜ | | | | |
| P04 | ⬜ | | | | |
| P05 | ⬜ | | | | |
| P06 | ⬜ | | | | |
| P07 | ⬜ | | | | |
| P08 | ⬜ | | | | |
| P09 | ⬜ | | | | |
| P10 | ⬜ | | | | |
| R01 | ⬜ | | | | |
| R02 | ⬜ | | | | |
| R03 | ⬜ | | | | |
| R04 | ⬜ | | | | |
| R05 | ⬜ | | | | |
| R06 | ⬜ | | | | |
| R07 | ⬜ | | | | |
| R08 | ⬜ | | | | |
| R09 | ⬜ | | | | |
| R10 | ⬜ | | | | |
| R11 | ⬜ | | | | |
| R12 | ⬜ | | | | |
| O01 | ⬜ | | | | |
| O02 | ⬜ | | | | |
| O03 | ⬜ | | | | |
| O04 | ⬜ | | | | |
| O05 | ⬜ | | | | |
| O06 | ⬜ | | | | |
| D01 | ⬜ | | | | |
| D02 | ⬜ | | | | |
| D03 | ⬜ | | | | |
| D04 | ⬜ | | | | |
| D05 | ⬜ | | | | |
| D06 | ⬜ | | | | |
| D07 | ⬜ | | | | |
| D08 | ⬜ | | | | |
| D09 | ⬜ | | | | |
| D10 | ⬜ | | | | |
| CAP | ⬜ | | | | |

## Nhật ký buổi học

### 2026-10-16 · F07 · Set operations (kết thúc)
- Làm: ex01–ex08 viết hôm 10-15, hôm nay chấm lại ✅ cả 8. ex09 nộp 2 lần (lần 1 sai nhóm "mua hàng", lần 2 đúng kết quả nhưng dùng `EXISTS` thay vì `INTERSECT`/`EXCEPT`), ex10 đúng ngay. F07 ✅ 9/10, 0 hint. Chi tiết: `lessons/F07-set-operations/review.md`
- Nắm chắc: `EXCEPT ALL` cho multiset (ex10), `NOT EXISTS`/`EXCEPT` an toàn với NULL, `count(col)` bỏ NULL (ex08), `EXCEPT` hai chiều
- Vấp: `DISTINCT`/`GROUP BY` thừa quanh phép tập hợp (ex04, ex06, ex08, ex10; ở ex10 làm đổi nghĩa), `UNION` thay `UNION ALL` (ex05, ex06), sót "đang bán" (ex05) và thiếu tiêu chí phụ trong `LIMIT`, đọc lệch định nghĩa "mua hàng" (ex09)
- Số đo: `shop_m`, 1 lần đo, ex04/06/07/09 chạy 0,7–2,8 s vì chưa có index trên `user_id`/`order_id` → chuyển P02
- Skill: coach quên nạp `sql-lesson`/`sql-review` ở lượt chấm đầu nên bỏ sót phần "nhận xét + best practice"; người học nhắc, đã bổ sung
- Đã dựng F08 (README, setup, exercises, `check.sh` riêng cho DML bọc BEGIN/ROLLBACK). F08 chạy trên `lab.f08`
- Buổi sau: F08 DML & UPSERT. Warm-up: F05 (đến hạn ôn hôm nay) + `date_trunc`/`AT TIME ZONE`. Còn nợ: ex09 viết lại bằng phép tập hợp (tùy chọn), bonus F07, S00/F01 quá hạn ôn, F01 ex09, bonus F04 ex06, bonus F06

### 2026-10-15 · F06 · Subqueries (kết thúc)
- Làm: ex01–ex05 viết hôm 10-13, hôm nay chạy `checks` và chấm lại ✅ cả 5. ex06–ex10 làm hôm nay. F06 ✅ 10/10, 0 hint. Đúng ngay lần đầu: ex01–ex05, ex07, ex08. Nộp nhiều lần: ex06 (3 lần), ex09 (2 lần), ex10 (2 lần)
- Nắm chắc: correlated subquery và scalar subquery trong `SELECT` (ex07 đếm cả danh mục 0 sản phẩm), `NOT EXISTS` an toàn với NULL, `avg` của tổng theo nhóm (ex08), `coalesce` cho tổng của tập rỗng (ex10), literal `+07` nửa mở đúng ở ex04, ex09, ex10
- Vấp: sót hoặc đọc lệch vế đề ở 3 bài (ex06 sai danh mục và thiếu round, ex09 sót "đã giao", ex10 "trừ" thành `= 'delivered'`); `round(select …)` thiếu cặp ngoặc subquery
- Số đo: ex06 subquery correlate chạy lại cho từng dòng (10,5 triệu buffer trên `shop_m`, chi phí tăng bình phương); ex07 gộp trước rồi `LEFT JOIN` nhanh gấp ~10 lần (37,5 → 3,7 ms); ex09 `EXISTS` nhanh hơn `JOIN` + `GROUP BY` (~129 so với ~274 ms, 1 lần đo); ex10 `payments` chỉ có index trên `id` nên mỗi subquery quét cả 1,04 triệu dòng, 118 471 đơn tháng 9 → trên `shop_m` đã chạy quá 2 phút chưa xong (hủy tay), planner ước tính chi phí ~3×10^10. Bọc subquery trong bảng dẫn xuất không đổi plan (planner tự gộp lại), chỉ dễ đọc hơn. Cách sửa thật là `CREATE INDEX` trên `payments(order_id)` (P02). Chưa làm bonus `NOT IN` vs `NOT EXISTS`
- Skill: thêm quy tắc "nhận xét và best practice sau khi đúng" vào `sql-lesson` và `sql-review` (theo yêu cầu người học)
- Buổi sau: F07 Set operations. Ôn: F05 mai (10-16), F04 và F06 10-18. Còn nợ: S00/F01 quá hạn ôn, F01 ex09 viết lại, bonus F04 ex06, bonus F06

### 2026-10-15 · Drill review (hỏi-đáp, không viết code)
- Làm: 8 câu, 22/29 ≈ 76%. Chi tiết: `drills/2026-10-15.md`. Docker chưa chạy nên chưa kiểm chứng bằng Postgres (Q1, Q7 cần chạy lại khi container lên)
- Nắm chắc: `NOT IN` với NULL → 0 dòng và dùng `NOT EXISTS` (câu 2), `float` vs `numeric` và `round` (câu 3 5/5), `count`/`avg`/`<>`/`IS DISTINCT FROM` (câu 6 5/5), fan-out 600 và hướng gộp trước rồi JOIN
- Vấp: `date_trunc` và literal thiếu múi giờ hiểu theo TimeZone của session (câu 1, 7 ❌, lần thứ 3 và 4); sót `>=` cho "từ … trở đi" (câu 4); nghĩ `COALESCE` cứu được đơn bị `INNER JOIN` loại (câu 5); OFFSET sâu quên sort toàn bảng khi không có index (câu 8)
- Cập nhật: `null-so-sanh` đủ streak 3 → đã khắc phục. F02, F03 đạt, ôn lại 2026-10-22. F04 chuyển 🔁 (date_trunc), ôn lại 2026-10-18. F05 vẫn ôn 2026-10-16. S00/F01 vẫn quá hạn, F01 ex09 vẫn còn nợ
- Buổi sau: F06 Subqueries (🟡), warm-up gồm `date_trunc` + `AT TIME ZONE` và `LEFT JOIN` với bảng con gộp trước

### 2026-10-13 · F05 · JOINs (kết thúc)
- Làm: warm-up 2/2 (câu 2 cần H1+H2), ex07–ex10 (ex07, ex09 đúng ngay; ex08, ex10 lần 2). ex01–ex06 làm hôm 10-12, chấm lại ✅. F05 ✅ 10/10, 0 hint
- Nắm chắc: `ON` vs `WHERE` với LEFT JOIN (ex07 đúng ngay), self join `a.id < b.id` (ex09 🔴 đúng ngay), gộp trước rồi JOIN để chữa fan-out (ex10 tự sửa)
- Vấp: ex10 lần 1 dính fan-out items × payments, INNER JOIN mất đơn chưa thanh toán, `sum FILTER` ra NULL, `1684`; ex08 sót "đã giao"; warm-up hiểu nhầm `timestamptz` lưu "+7"
- Bonus ex03: người học xin đáp án, coach đo trên `shop_m` (205 ms, quét hết `orders`; `o.id IS NULL` không thành anti join, `o.user_id IS NULL` thì có, 137 ms)
- Đã dựng F06 (README, exercises, checks). Bonus F06: `NOT IN` trên `shop_m` > 60 s so với `NOT EXISTS` 0.5 s
- Buổi sau: F06 Subqueries. Còn nợ: F01 ex09 viết lại; S00/F01 quá hạn ôn, F02–F04 ôn 2026-10-15 (lồng vào warm-up)

### 2026-10-12 · F04 · Aggregates
- Làm: 10/10 ✅, 0 hint. Đúng ngay lần đầu 3/10 (ex01, ex02, ex09). Warm-up: câu 1 ❌ (`NOT IN` có NULL), câu 2 hoãn. Bonus quy mô ex06 chưa làm
- Nắm chắc: `WHERE` vs `HAVING` (đúng cả 10 bài, ex09 🔴 đúng ngay), `count(*)/count(col)/count(DISTINCT)`, `FILTER`, tỉ lệ `100.0 *` trước phép chia, `string_agg … ORDER BY`
- Vấp: 5 bài ❌ lần đầu chỉ vì tên cột/nhãn lệch đề (ex03, ex04, ex05, ex07, ex08); ex06 `date_trunc` theo UTC dù WHERE theo giờ VN; ex10 đếm lần thanh toán trên `orders`
- Ghi chú: gợi ý tự chạy `check.sh` trước khi nộp (không bắt buộc). `chia-so-nguyen` chuyển sang đã khắc phục
- Buổi sau: F05 JOIN. Còn nợ: F01 ex09 viết lại, warm-up F04 câu 2; S00/F01 quá hạn ôn, F02–F04 ôn 2026-10-15

### 2026-10-12 · F03 · NULL
- Làm: 10/10 ✅ (6/10 đúng ngay lần đầu), 3 hint (H1 ×3: ex02, ex09, ex10). Warm-up 1.5/2
- Nắm chắc: `IS DISTINCT FROM` (ex03, ex08 đúng ngay), COALESCE/NULLIF/NULLS LAST, `count(col)`, `avg` bỏ qua NULL và ý nghĩa nghiệp vụ; ép kiểu trước khi chia và literal thời gian đều đúng
- Vấp: `doc-thieu-de` 4 lần, ex09 mất 4 lần nộp vì sót 3 điều kiện in đậm; ex10 lần đầu vẫn viết `<>` trên cột có NULL
- Ghi chú: đề ex10 viết chưa chặt về phạm vi thời gian, người học phản biện đúng, đề đã được sửa
- Buổi sau: drill 10–15' (S00/F01 quá hạn, F01 ex09 còn nợ, `doc-thieu-de`, `null-so-sanh`) rồi F04 Aggregates

### 2026-10-12 · F02 · Data types (kết thúc)
- Làm: warm-up 3 câu (2.5/3 · ✅ · 2/3), chấm lại ex02–ex09 (✅ cả 8), làm lại ex01 (2 lần nộp) và ex10 (2 lần nộp, H1×1), bonus text vs uuid. F02 ✅ 10/10, 1 hint
- Nắm chắc: float vs numeric cho tiền, `round(float8)` làm tròn về số chẵn, `AT TIME ZONE` hai chiều, literal ISO + múi giờ + nửa mở (warm-up câu 2 đúng không cần nhắc)
- Vấp: chia số nguyên cắt phần lẻ trước `round` (warm-up câu 3, ex10 lần 1); `order.created_at` (đoán tên bảng); ex05/ex06 đúng nhờ chi tiết cài đặt chứ chưa nói đúng ý đồ
- Bonus: dự đoán +160 MB ở 10M; đo thật ~+229 MB bảng và ~+346 MB index (căn lề 8 byte, page split do UUID ngẫu nhiên)
- Ghi chú: người học muốn nhận đề **từng câu một**, không dồn nhiều bài một lúc
- Buổi sau: drill 10–15' (S00/F01 quá hạn ôn, F01 ex09 còn nợ, `chia-so-nguyen`) rồi F03 NULL & 3-valued logic

### 2026-10-09 · Drill review (trước F02)
- Làm: 2/7 câu đạt (câu 1 đạt 4/6 vế), câu 8 (viết lại F01 ex09) bỏ qua, vẫn còn nợ. Chi tiết: `drills/2026-10-09.md`
- Nắm chắc: độ ưu tiên AND/OR, FK không tự tạo index (kiểm tra bằng `\d`/EXPLAIN), dịch cụm đơn lẻ sang toán tử
- Vấp: sót vế đề ở 3 câu dù đã được đưa checklist; literal thời gian (không nháy, thiếu `+00`); so sánh với NULL; đoán tên cột
- Buổi sau: tiếp F02 ngay trong hôm nay; F01 ex09 + checklist để vào drill kế tiếp

### 2026-10-08 · F01 · SELECT cơ bản
- Làm: 9/10 bài đạt, 0 hint. ex09 🔑 xin đáp án sau 3 lần nộp (lỗi `>=`, literal ISO + múi giờ, tiêu chí phụ `id`)
- Nắm chắc: ORDER BY có tiêu chí phụ, thứ tự logic (alias không dùng được trong WHERE), `IN` thay cho OR, `IS NULL`, NULLS LAST khi ASC
- Vấp: pass nhờ dữ liệu trùng hợp (ex08 lọc brand thay cho name; ex09 `>`, quên năm, chuỗi ngày MDY); quên ORDER BY (ex03), thiếu điều kiện (ex05)
- Bonus ex06: dự đoán OFFSET 10 và OFFSET 499995 chạy như nhau là sai (478 ms so với 803 ms, sort tràn đĩa 67 MB); tưởng index trên `id` giúp `ORDER BY created_at`
- Buổi sau: F02 Data types; drill viết lại ex09 không nhìn đáp án (timestamptz sẽ giải quyết tận gốc lỗi `literal-thoi-gian`)

### 2026-10-07 · S00 · Môi trường
- Dựng: Postgres 18 (`sql-practice-pg`, cổng 5433), sinh shop_xs/s/m, bench chạy được (top-cities: 0.19ms → 6.29ms → 563ms)
- Làm: 4/5 câu psql, 0 hint
- Nắm chắc: `\l \c \dt \d \timing`, SELECT đầu tiên, trực giác "data ×100 thì thời gian tăng mạnh"
- Vấp: trả lời thiếu vế (câu 2, 3); nhầm DB đang kết nối (shop_m tưởng shop_s)
- Buổi sau: F01

<!-- Mới nhất ở trên. Mẫu:
### 2026-10-08 · F01 · 75'
- Làm: 9/10 bài, 2 hint (H1×2)
- Nắm chắc: ...
- Vấp: ...
- Buổi sau: F02
-->
