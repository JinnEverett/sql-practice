# P08 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Lệnh nào lấy lock gì
<details><summary>H1</summary><code>pg_locks</code> có cột <code>mode</code>, <code>relation</code>, <code>pid</code>.</details>
<details><summary>H2</summary>Trong transaction: chạy lệnh rồi <code>SELECT mode FROM pg_locks WHERE relation = 'p08.t'::regclass AND pid = pg_backend_pid()</code>.</details>
<details><summary>H3</summary>Tên mode: <code>AccessShareLock</code>, <code>RowShareLock</code>, <code>RowExclusiveLock</code>, <code>ShareLock</code>, <code>AccessExclusiveLock</code>.</details>

## ex02 · Worker lấy việc
<details><summary>H1</summary>Cần khóa dòng nhưng bỏ qua dòng đã bị khóa.</details>
<details><summary>H2</summary><code>… FOR UPDATE SKIP LOCKED</code> trong subquery <code>ORDER BY id LIMIT 1</code>.</details>
<details><summary>H3</summary><code>UPDATE p08.jobs SET state='taken' WHERE id = (SELECT id FROM p08.jobs WHERE state='new' ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED);</code></details>

## ex03 · Chuyển tiền ngược chiều
<details><summary>H1</summary>Deadlock cần vòng chờ. Phá vòng bằng cách để mọi giao dịch lấy khóa theo cùng một thứ tự.</details>
<details><summary>H2</summary>Khóa cả hai dòng ngay đầu transaction theo thứ tự id tăng dần, trước khi sửa.</details>
<details><summary>H3</summary><code>SELECT id FROM p08.acct WHERE id IN (:from, :to) ORDER BY id FOR UPDATE;</code> ngay sau <code>BEGIN</code>.</details>

## ex04 · Deploy làm site đứng
<details><summary>H1</summary>ALTER chờ lock thì chặn luôn người đến sau. Cách duy nhất để không chặn lâu là đừng chờ lâu.</details>
<details><summary>H2</summary>Tham số <code>lock_timeout</code> đặt trước lệnh DDL.</details>
<details><summary>H3</summary><code>SET lock_timeout = '1s'; ALTER TABLE p08.big ADD COLUMN x int;</code></details>

## ex05 · Cron chạy một mình
<details><summary>H1</summary>Advisory lock có hai biến thể: chờ và không chờ.</details>
<details><summary>H2</summary><code>pg_try_advisory_lock(42)</code> trả boolean; dùng nó làm điều kiện <code>WHERE</code> của <code>INSERT … SELECT</code>.</details>
<details><summary>H3</summary><code>INSERT INTO p08.runs SELECT 'ran' WHERE pg_try_advisory_lock(42);</code></details>

## ex06 · Đọc log deadlock
<details><summary>H1</summary>Mỗi dòng "Process X waits for … blocked by process Y" là một cạnh của đồ thị chờ.</details>
<details><summary>H2</summary>Hai câu lệnh trong log cho biết hai đường mã khác nhau chạm cùng các dòng theo thứ tự ngược nhau.</details>
<details><summary>H3</summary>Xem <code>log_lock_waits</code> và <code>deadlock_timeout</code>.</details>

## ex07 · Hàng đợi với số worker
<details><summary>H1</summary>Không SKIP LOCKED thì mọi worker tranh cùng một dòng đầu hàng đợi.</details>
<details><summary>H2</summary>Thông lượng của đoạn tuần tự không tăng khi thêm worker.</details>
<details><summary>H3</summary>Đo với <code>pgbench -c 1/4/8</code>; container chỉ có 4 nhân.</details>
