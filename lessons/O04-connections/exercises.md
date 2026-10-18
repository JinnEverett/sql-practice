# O04 · Bài tập (Connections)

Bài 1–3 chạy trên DB **`lab`**, schema `o04` (script chấm tự chạy `setup.sql`). Mỗi bài là **một câu `SELECT`** vào `answers/exNN.sql`; tự chấm: `bash tools/check.sh lessons/O04-connections 01`.
Bài 4–8 là thí nghiệm thật (`mode: manual`), đối chiếu với `solutions/exNN.md` (số đo thật, Postgres 18.6, 8 CPU).

Chuẩn bị cho bài 4–8 (DB tạm, xóa sau khi xong):
```bash
docker exec sql-practice-pg psql -U postgres -c "CREATE DATABASE o04_bench"
docker exec sql-practice-pg pgbench -i -s 10 -q -U postgres o04_bench
# dọn: docker exec sql-practice-pg psql -U postgres -c "DROP DATABASE o04_bench"
```
Bài 5, 7 cần PgBouncer: cách dựng một container tạm nằm trong `solutions/ex05.md`; tự làm trước, đừng mở lời giải ngay.

**Pass:** 7/8 (3 bài chấm tự động + 5 bài tự đối chiếu).

---

## 🟢 Cơ bản

### ex01 · Kết nối dùng được
Từ `pg_settings`, tính số kết nối mà một **role thường** (không phải superuser, không thuộc `pg_use_reserved_connections`) có thể mở: `max_connections` trừ đi mọi phần dành riêng.
- Cột: `usable_connections` (số nguyên) · Một dòng
- Kỳ vọng: **1 dòng**; trên server này là 97.

### ex02 · Ngân sách kết nối
Bảng `o04.apps` cho biết mỗi dịch vụ chạy bao nhiêu bản (`instances`) và mỗi bản mở pool bao nhiêu kết nối (`pool_size`). Giả sử `max_connections = 100`, `superuser_reserved_connections = 3`, `reserved_connections = 0`. Cho mỗi dịch vụ, tính tổng kết nối nó có thể mở, **cộng dồn** theo thứ tự dịch vụ tốn nhiều nhất trước, và cho biết phần cộng dồn đó còn **vừa** trong số kết nối dùng được không.
- Cột: `app`, `total_conns`, `running_total`, `fits` (boolean) · Sắp xếp: `total_conns` giảm dần
- Kỳ vọng: **5 dòng**; dòng đầu là `api` (60); có đúng 2 dòng `fits = true`.

---

## 🟡 Kết hợp

### ex03 · Kết nối nên cắt
`o04.activity_snapshot` là ảnh chụp `pg_stat_activity` lúc sự cố. Liệt kê các kết nối nên `pg_terminate_backend`, theo quy tắc: (a) đang ở trạng thái `idle in transaction` (**kể cả** `idle in transaction (aborted)`) quá **60 giây** kể từ lần đổi state; (b) `idle` quá **900 giây**. Không bao giờ cắt user `monitor`. Ghi lý do là `idle_in_tx` hoặc `idle_long`.
- Cột: `pid`, `usename`, `application_name`, `reason` · Sắp xếp: `pid`
- Kỳ vọng: **5 dòng**; dòng đầu là pid 101.

### ex04 · Đo giá của một kết nối (manual)
Trên `o04_bench`, đo thông lượng `pgbench -S -c4 -j2 -T8` với kết nối bền và với `-C` (mở kết nối mới cho mỗi giao dịch). Tính hệ số chậm đi, rồi lặp lại `-C` nhưng đi qua **TCP** (`-h` tới host, có SCRAM) thay vì unix socket. Mở kết nối chiếm bao nhiêu mili-giây, so với một truy vấn?

### ex05 · Cấu hình PgBouncer (manual)
Có 8 bản ứng dụng, mỗi bản giữ pool 40 kết nối (tổng 320 client) nhưng Postgres chỉ dùng được 97. Dựng PgBouncer chế độ **transaction** trước `o04_bench` sao cho cả 320 client chạy được mà server chỉ nhận tối đa 10 kết nối. Viết `pgbouncer.ini`, chạy `pgbench -S -c300` qua nó, so với chạy thẳng, đọc `SHOW POOLS`. Giải thích từng tham số bạn chọn.

---

## 🔴 Thực tế

### ex06 · "Cao điểm là app báo lỗi kết nối" (manual)
Team báo: *"Mỗi tối 8 giờ API trả 500, log đầy `sorry, too many clients already`, mà CPU database chỉ 20%."* Tái hiện bằng `pgbench`, điều tra bằng `pg_stat_activity` (ai chiếm, state gì), rồi xếp hạng các cách chữa theo hiệu quả và rủi ro: tăng `max_connections`, giảm pool ở ứng dụng, PgBouncer, cắt `idle in transaction`, `idle_session_timeout`.

### ex07 · "Bật PgBouncer xong thì app lỗi lung tung" (manual)
Sau khi chuyển sang `pool_mode = transaction`, ứng dụng bắt đầu: (1) timeout bất thường ở request không liên quan; (2) job nền cạnh tranh lock lạ; (3) `prepared statement "q1" does not exist`. Tái hiện cả ba bằng pool nhỏ (`pool_size = 1` và `2`) với nhiều client xen kẽ, giải thích cơ chế và sửa đúng cho từng cái mà **không** quay về session mode.

---

## 📏 ex08 · Câu hỏi quy mô: bao nhiêu kết nối thì đủ?
Máy 8 CPU, `pgbench -S` (select-only, scale 10). **Dự đoán** (viết ra trước) thông lượng ở 1, 8, 32, 64 kết nối, và nói **từ đâu trở đi** thêm kết nối không còn giúp ích. Rồi đo cả `-S` lẫn TPC-B mặc định (có ghi, tranh chấp khóa dòng) và giải thích vì sao đường cong của chúng khác nhau. Một API có 400 request đồng thời nên cấu hình pool bao nhiêu?
Lời giải và số đo thật: `solutions/ex08.md`.
