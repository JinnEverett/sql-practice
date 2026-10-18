# R04 · Bài tập (Job queue)

Tất cả chạy trên **DB `lab`** schema `r04` (script chấm tự chạy `setup.sql`: 11 job với ưu tiên, giờ hẹn và trạng thái khác nhau; xem file để biết dữ liệu).
Bài 1–4 là câu `UPDATE` chấm bằng trạng thái bảng (và output `RETURNING`); bài 5–6 mô phỏng **nhiều session đồng thời** bằng `dblink` (bộ chấm tự dựng); bài 7 và 8 tự đối chiếu.
Tự chấm: `bash tools/check.sh lessons/R04-job-queue 01`.

Quy ước chung: worker tên `'worker-1'`; `status` hợp lệ: `queued | running | done | dead`; job nhận được khi `status = 'queued' AND run_at <= now()`; thứ tự ưu tiên: `priority` giảm dần, rồi `run_at` tăng dần, rồi `id` tăng dần.

**Pass:** 6/8, trong đó **bắt buộc đúng bài 5 và 6** ("queue chạy đúng với nhiều worker").

---

## 🟢 Cơ bản

### ex01 · Nhận một job
Viết **một câu** nhận job ưu tiên cao nhất: đặt `status = 'running'`, tăng `attempts` 1, ghi `locked_at = now()`, `locked_by = 'worker-1'`, và `RETURNING id`. Nhiều worker chạy câu này cùng lúc không được chờ nhau.
- Kiểm tra: trạng thái bảng và output (job được nhận là `id 3`)

### ex02 · Nhận theo lô
Như ex01 nhưng nhận **3 job** một lần.
- Kiểm tra: trạng thái bảng và output (job `3, 2, 7` chuyển sang `running`)

---

## 🟡 Kết hợp

### ex03 · Báo thất bại, retry, dead-letter
Worker báo hai job đang chạy, `id 5` (đã nhận 1/3 lượt) và `id 9` (đã nhận 3/3 lượt), thất bại với lỗi `'timeout'`. Viết **một câu** `UPDATE … WHERE id IN (5, 9)` sao cho: job còn lượt thử quay lại `queued` và hẹn chạy lại sau `10 giây × 2^attempts`; job hết lượt thử thành `dead`; cả hai nhả khóa (`locked_at`, `locked_by` = NULL) và ghi `last_error = 'timeout'`.
- Kiểm tra: trạng thái hai job (job 5: `queued`, chạy lại sau 20 giây; job 9: `dead`)

### ex04 · Thu hồi job treo
Worker chết để lại job `running` quá lâu. Thu hồi các job `running` mà `locked_at` cách hiện tại **hơn 5 phút**: còn lượt thử thì về `queued`, hết lượt thì `dead`; nhả khóa; ghi `last_error = 'reclaimed: worker timeout'`. Job mới nhận (job 5, 9) không được đụng tới.
- Kiểm tra: trạng thái bảng (job 10 → `queued`, job 11 → `dead`, job 5 và 9 vẫn `running`)

---

## 🔴 Thực tế

### ex05 · Hai worker, không chờ nhau (2 session)
Viết lại câu nhận job (như ex01) sao cho khi worker A đã nhận job 3 và **chưa commit**, worker B chạy cùng câu đó nhận được job 2 **ngay lập tức** (bộ chấm đặt `lock_timeout = 300ms` cho B). Bộ chấm chạy A bằng `dblink` giữ transaction mở 1.5 giây.
- Kiểm tra bằng bộ test (A nhận job 3, B nhận job 2, không lỗi chờ khóa)

### ex06 · Ba worker xử lý hết hàng đợi (nhiều session)
Câu trả lời vẫn là một câu nhận job `UPDATE … RETURNING id` (giống ex05). Bộ chấm thêm 60 job rồi chạy **3 worker song song**, mỗi worker lặp: nhận job → ghi log → làm việc 10 ms → đặt `done`, dừng khi nhận `NULL`. Kiểm tra: mỗi job được xử lý đúng một lần, job hẹn giờ không bị nhận, job `running` có sẵn không bị đụng.
- Kiểm tra bằng bộ test

### ex07 · Đánh thức worker bằng NOTIFY (tự đối chiếu)
Worker đang poll mỗi giây. Thiết kế phương án dùng `LISTEN/NOTIFY` để đánh thức: viết trigger `AFTER INSERT` gửi `pg_notify`, rồi dùng hai cửa sổ `psql` (một cửa sổ `LISTEN`, một cửa sổ chèn job) để trả lời bằng quan sát thật (ghi vào `answers/ex07.md`): (a) thông báo đến lúc nào, khi `INSERT` hay khi `COMMIT`? (b) transaction `ROLLBACK` thì sao? (c) chèn 1000 job trong một transaction có gửi 1000 thông báo không? (d) worker khởi động muộn thì thấy gì? (e) vì sao vẫn cần vòng poll dự phòng?
Đối chiếu: `solutions/ex07.md` (có kết quả thật).

---

## 📏 ex08 · Câu hỏi quy mô: câu nhận job khi có nhiều job đã xong
Bảng `jobs` có 1 000 job `queued` và N − 1 000 job `done`. Câu nhận job:
```sql
SELECT id FROM jobs WHERE status = 'queued' AND run_at <= now()
ORDER BY priority DESC, run_at, id LIMIT 1 FOR UPDATE SKIP LOCKED;
```
1. **Dự đoán** (ghi vào `answers/ex08.md`): thời gian và số buffer ở N = 10k, 100k, 1M cho ba phương án: (a) chỉ có PK, (b) index `(priority DESC, run_at, id)`, (c) cùng index nhưng **partial** `WHERE status = 'queued'`. Phương án nào tăng theo N? Phương án nào tệ hơn không có index?
2. Tự dựng bảng (xem `solutions/ex08.sql`) và đo bằng `EXPLAIN (ANALYZE, BUFFERS)`.
3. Giải thích điểm gãy. Rồi trả lời: nếu job `done` chiếm 99.9% bảng, bạn xử lý lịch sử bằng cách nào?

Lời giải và số đo thật: `solutions/ex08.md`.
