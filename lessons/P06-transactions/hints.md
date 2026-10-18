# P06 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Chuyển tiền và thu phí
<details><summary>H1</summary>Cần một cách gom 3 lệnh thành một đơn vị: tất cả hoặc không gì.</details>
<details><summary>H2</summary><code>BEGIN; …; COMMIT;</code>. Lệnh thứ ba lỗi thì transaction ở trạng thái aborted.</details>
<details><summary>H3</summary>Không cần bắt lỗi: <code>COMMIT</code> của transaction đã lỗi tự thành rollback.</details>

## ex02 · Nhập lô một phần
<details><summary>H1</summary>Một lệnh lỗi làm hỏng cả transaction. Có cách đặt "điểm quay lại" ở giữa.</details>
<details><summary>H2</summary><code>SAVEPOINT s;</code> trước lệnh có thể lỗi, <code>ROLLBACK TO SAVEPOINT s;</code> sau lỗi.</details>
<details><summary>H3</summary>Đặt savepoint ngay trước <code>INSERT … 'A1'</code>, rollback về nó, rồi chèn <code>C3</code>, <code>COMMIT</code>.</details>

## ex03 · Đọc hai lần cùng một số
<details><summary>H1</summary>Mỗi lệnh ở mức mặc định thấy dữ liệu mới nhất đã commit. Mức nào cho cả transaction một snapshot?</details>
<details><summary>H2</summary><code>READ UNCOMMITTED</code> của Postgres không giúp. Hoặc khóa dòng ngay lúc đọc lần đầu.</details>
<details><summary>H3</summary><code>BEGIN ISOLATION LEVEL REPEATABLE READ;</code></details>

## ex04 · Hai người cùng cộng tiền
<details><summary>H1</summary>Giá trị đã đọc ở bước 1 đã cũ khi bạn ghi. Đừng ghi lại số đã tính; để cơ sở dữ liệu tính tại thời điểm ghi.</details>
<details><summary>H2</summary><code>SET balance = balance + 30</code>. Cách khác: khóa dòng ở bước đọc.</details>
<details><summary>H3</summary>Dùng <code>REPEATABLE READ</code> sẽ bị lỗi 40001 vì dòng đã bị B sửa sau snapshot của A: phải retry, nên giữ <code>READ COMMITTED</code>.</details>

## ex05 · Đếm đơn mở hai lần
<details><summary>H1</summary>Phantom: cùng điều kiện, thêm dòng mới giữa hai lần. Cần snapshot cố định.</details>
<details><summary>H2</summary>Chuẩn SQL nói phải SERIALIZABLE để chặn phantom. Postgres có mức yếu hơn mà vẫn chặn được.</details>
<details><summary>H3</summary><code>REPEATABLE READ</code>.</details>

## ex06 · Hết người trực
<details><summary>H1</summary>Hai bên sửa hai dòng khác nhau nên không có xung đột ghi. Cần cơ chế biết "hai bên đọc cùng một tập".</details>
<details><summary>H2</summary>Họ 1: <code>SERIALIZABLE</code>, một bên sẽ bị 40001. Họ 2: khóa cả tập trước khi quyết định (<code>FOR UPDATE</code>) và để <code>UPDATE</code> kiểm tra lại điều kiện.</details>
<details><summary>H3</summary>Họ 1: <code>BEGIN ISOLATION LEVEL SERIALIZABLE;</code>. Họ 2: <code>SELECT * FROM p06.doctor WHERE on_call FOR UPDATE;</code> rồi <code>UPDATE … WHERE id = :me AND (SELECT count(*) FROM p06.doctor WHERE on_call) &gt;= 2;</code></details>

## ex07 · Giá của isolation level
<details><summary>H1</summary>Khi nhiều client sửa cùng một dòng, RR/SERIALIZABLE hủy giao dịch thay vì cho chờ.</details>
<details><summary>H2</summary>Tỉ lệ lỗi phụ thuộc xác suất hai giao dịch chạm cùng dòng: 8 client trên 4 dòng so với trên 1 000 dòng.</details>
<details><summary>H3</summary><code>pgbench --max-tries=N</code> tự retry lỗi 40001/40P01 và báo "transactions retried".</details>
