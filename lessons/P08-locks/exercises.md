# P08 · Bài tập (Locks & deadlocks)

Tất cả chạy trên DB **`lab`** schema `p08` (script chấm tự chạy `setup.sql`). Cần user `postgres`. Bài làm là script SQL trong `answers/exNN.sql`; tự chấm: `bash tools/check.sh lessons/P08-locks 02`.
**Bài nhiều session (ex02–ex05):** check bật các session phụ ở nền (tiến trình `psql` riêng), ép thứ tự bằng `sleep`. Với ex03, bài làm là script của **một** luồng chuyển tiền, có dòng riêng `-- >>> B` chia 2 đoạn; check chạy **hai bản** đồng thời (A với `:from=1, :to=2`, B với `:from=2, :to=1`). Hãy tự tái hiện bằng hai cửa sổ `psql` trước.
Mỗi bài chấm tốn vài giây (có `sleep`); đừng chạy hai lần chấm song song vì dùng chung `lab`.

**Pass:** "Tái hiện & sửa 1 deadlock": ex03 bắt buộc, tổng ≥ 6/7 bài.

---

## 🟢 Cơ bản

### ex01 · Lệnh nào lấy lock gì
Thử trong transaction rồi xem `pg_locks` cho `p08.t` (`relation = 'p08.t'::regclass`): `SELECT`, `SELECT … FOR UPDATE`, `UPDATE`, `CREATE INDEX`, `ALTER TABLE … ADD COLUMN`. Trả về bảng (lệnh, lock mode mức bảng).
- Cột: `stmt, table_lock_mode` · Sắp xếp: `table_lock_mode`, `stmt`
- Kỳ vọng: **5 dòng**, dòng đầu `ALTER TABLE ADD COLUMN | AccessExclusiveLock`

### ex02 · Worker lấy việc
`p08.jobs(id, state)` có 5 việc `new`. Session B đang giữ khóa dòng của job 1 (4 giây). Viết lệnh của một worker: lấy **việc `new` nhỏ nhất chưa bị ai khóa** và đổi `state = 'taken'`, **không chờ** B. Kết quả: job 2 `taken`, job 1 vẫn `new`, đúng 1 job được lấy.

---

## 🟡 Kết hợp

### ex03 · Chuyển tiền ngược chiều (deadlock)
```sql
BEGIN;
UPDATE p08.acct SET balance = balance - 10 WHERE id = :from;
-- >>> B
UPDATE p08.acct SET balance = balance + 10 WHERE id = :to;
INSERT INTO p08.xfer_log VALUES (:from, :to);
COMMIT;
```
Chạy bản này đồng thời cho `1→2` và `2→1` thì gặp `deadlock detected`. **Bước 1:** tái hiện bằng hai cửa sổ `psql` (ghi lại log). **Bước 2:** sửa script (có thể thêm lệnh, không thêm retry) để cả hai lần chuyển đều commit, số dư cuối vẫn 100, 100 và không có deadlock.

### ex04 · Deploy làm site đứng
Team báo: deploy `ALTER TABLE p08.big ADD COLUMN x int` làm **mọi truy vấn trên `big` đứng** hơn 30 giây dù lệnh ALTER rất nhanh. Nguyên nhân: lúc deploy có một báo cáo đọc dài. Check dựng đúng cảnh đó (báo cáo 7 giây, một người dùng `SELECT` vào giữa lúc bạn chạy migration) và đo thời gian người dùng bị chặn. Viết script migration để người dùng bị chặn **dưới 3 giây** (migration được phép thất bại để chạy lại sau), và script vẫn phải chứa lệnh `ALTER TABLE`.

### ex05 · Cron chạy một mình
Job báo cáo chạy mỗi phút; đôi khi bản trước chưa xong thì bản sau chạy chồng. Viết script của job: chỉ chạy phần việc (`INSERT INTO p08.runs VALUES ('ran')`) nếu **lấy được khóa advisory số 42**, nếu không thì **bỏ qua ngay, không chờ**. Check: khi một session khác đang giữ khóa 42, job không ghi gì; khi khóa rảnh, job ghi đúng 1 dòng.

---

## 🔴 Thực tế

### ex06 · "Hôm nào cũng có deadlock"
Team gửi log:
```
ERROR:  deadlock detected
DETAIL:  Process 14233 waits for ShareLock on transaction 515922; blocked by process 14227.
	Process 14227 waits for ShareLock on transaction 515923; blocked by process 14233.
	Process 14233: UPDATE p08.acct SET balance = balance + 10 WHERE id = 1;
	Process 14227: UPDATE p08.acct SET balance = balance + 10 WHERE id = 2;
CONTEXT:  while updating tuple (0,1) in relation "acct"
```
Trong `answers/ex06.md` trả lời: (1) ai chờ ai? (2) tiến trình nào bị hủy và vì sao? (3) tài nguyên bị tranh? (4) nguyên nhân gốc ở đường mã nào? (5) sửa thế nào? (6) cấu hình nào giúp thấy cả các lần chờ chưa thành deadlock? Đối chiếu `solutions/ex06.md`.

---

## 📏 Câu hỏi quy mô

### ex07 · Hàng đợi với số worker tăng dần
**Dự đoán:** 200 000 việc, mỗi worker lấy việc rồi xử lý 2 ms. Thông lượng (tps) với 1, 4, 8 worker khi lấy việc bằng `FOR UPDATE` thường so với `FOR UPDATE SKIP LOCKED`? Đo bằng `pgbench` (xem `solutions/ex07.md`) và giải thích khác biệt.
