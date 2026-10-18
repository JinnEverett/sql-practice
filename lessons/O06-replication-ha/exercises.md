# O06 · Bài tập (Replication & HA)

Bài 1–3 chạy trên DB **`lab`**, schema `o06` (script chấm tự chạy `setup.sql`: dữ liệu LSN cố định, không cần replica thật). Mỗi bài là **một câu `SELECT`** vào `answers/exNN.sql`; tự chấm: `bash tools/check.sh lessons/O06-replication-ha 01`.
Bài 4–8 là thí nghiệm thật (`mode: manual`), đối chiếu với `solutions/exNN.md` (số đo thật, Postgres 18.6). Chúng chạy trong **container tạm** trong một mạng Docker riêng; dọn sau khi xong:
```bash
docker network create o06-net
# ... docker run --name o06-primary --network o06-net ... (xem ex04)
# dọn: docker rm -f -v <các container o06-*>;  docker network rm o06-net
```
Mạng nội bộ nên lag đo được là **cận dưới** so với kết nối giữa hai vùng.

**Pass:** 7/8 (3 bài chấm tự động + 5 bài tự đối chiếu). Gợi ý: bài 4 là tiêu chí chính ("dựng 1 replica bằng Docker").

---

## 🟢 Cơ bản

### ex01 · Lag theo từng chặng (byte)
Bảng `o06.replica_status` là ảnh chụp `pg_stat_replication` của 5 replica. Cho mỗi replica tính ba số **byte**: `transfer_lag_bytes` (đã gửi nhưng chưa flush ở replica: `sent − flush`), `apply_lag_bytes` (đã flush nhưng chưa replay: `flush − replay`) và `total_lag_bytes` (`sent − replay`). Dùng hàm so sánh LSN của Postgres.
- Cột: `replica`, `transfer_lag_bytes`, `apply_lag_bytes`, `total_lag_bytes` · Sắp xếp: `total_lag_bytes` giảm dần, rồi `replica`
- Kỳ vọng: **5 dòng**; dòng đầu là `r4` (96 MB), dòng cuối là `r1` (0).

### ex02 · Replica nào đáng báo động?
Phân loại mỗi replica trong `o06.replica_status`: `NOT_STREAMING` nếu `state` khác `streaming`; ngược lại `LAGGING` nếu `total_lag_bytes` (`sent − replay`) lớn hơn **16 MB** (16 777 216 byte) **hoặc** `replay_lag` lớn hơn **5 giây**; còn lại `OK`. Chú ý `replay_lag` là `NULL` khi replica nhàn rỗi và đã bắt kịp.
- Cột: `replica`, `status` · Sắp xếp: `replica`
- Kỳ vọng: **5 dòng**; `r1` và `r5` là `OK`, `r2` và `r3` là `LAGGING`, `r4` là `NOT_STREAMING`.

---

## 🟡 Kết hợp

### ex03 · Định tuyến đọc sau khi ghi (read-your-writes)
`o06.sessions` lưu LSN lần ghi gần nhất của mỗi người dùng (`NULL` = chưa ghi); `o06.replicas_now` lưu vị trí replay hiện tại của các replica. Một replica **đủ mới** cho người dùng nếu `replay_lsn` của nó **không nhỏ hơn** LSN lần ghi của người đó. Cho mỗi người dùng, cho biết số replica đủ mới và nơi nên đọc: `replica` nếu có ít nhất một replica đủ mới, ngược lại `primary`. Người chưa từng ghi thì replica nào cũng được.
- Cột: `user_id`, `eligible_replicas`, `route` · Sắp xếp: `user_id`
- Kỳ vọng: **6 dòng**; user 6 là `primary` (0 replica đủ mới); user 4 (chưa ghi) có 3 replica đủ mới.

### ex04 · Dựng một replica bằng Docker (manual)
Dựng một primary và một replica streaming bằng `postgres:18`, trong mạng Docker riêng. Ghi rõ từng bước: role, `pg_hba.conf`, `pg_basebackup` (kèm `-R` và slot). Chứng minh: (1) `pg_stat_replication` trên primary cho `state = streaming`, (2) dữ liệu ghi ở primary xuất hiện ở replica, (3) replica từ chối ghi, (4) `pg_is_in_recovery()`. Giải thích `-R`, `-X stream`, `-C -S` làm gì.

### ex05 · Replica lag và dữ liệu "đọc không thấy" (manual)
Đo lag byte và thời gian lúc rảnh, lúc có tải ghi (`pgbench`), và lúc nạp hàng loạt. Rồi tái hiện read-your-writes bằng cách tạm dừng replay trên replica: ghi ở primary, đọc ngay ở replica, đối chiếu LSN. Đề xuất và so sánh ít nhất ba cách xử lý.

---

## 🔴 Thực tế

### ex06 · "Primary chết lúc 3 giờ sáng" (manual)
Primary dừng đột ngột. Promote replica, ghi tiếp vào primary mới, rồi **khởi động lại primary cũ** như thể nó tự bật lại. Chứng minh split-brain bằng dữ liệu rẽ nhánh, rồi đưa primary cũ về làm replica của primary mới (`pg_rewind`). Liệt kê mọi thứ cần có để quá trình đó chạy, kể cả những bước dễ quên. Kể tên điều Patroni làm hộ.

### ex07 · Logical replication (manual)
Dựng publication/subscription giữa hai instance. Tái hiện từng bẫy: bảng không có khóa trên publisher, sequence, DDL không được sao chép, subscription kẹt làm publisher giữ WAL, ghi trùng khóa ở subscriber. Khi nào nên chọn logical thay vì streaming?

---

## 📏 ex08 · Câu hỏi quy mô: lag sẽ ra sao?
**Dự đoán** (viết ra trước): (a) replay lag lớn nhất khi nạp 4 triệu dòng (~540 MB WAL) trên máy này; (b) chuyện gì xảy ra với truy vấn 20 s chạy trên replica khi primary xóa 150 000 dòng rồi VACUUM, với `max_standby_streaming_delay = 5s`, ở hai chế độ `hot_standby_feedback` off/on. Rồi đo. Nếu replica ở cách primary 80 ms mạng, con số nào thay đổi và con số nào không?
Lời giải và số đo thật: `solutions/ex08.md`.
