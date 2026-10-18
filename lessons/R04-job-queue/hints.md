# R04 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Nhận một job
<details><summary>H1</summary>Chọn job và đổi trạng thái phải xảy ra trong cùng một câu lệnh. Chọn bằng subquery.</details>
<details><summary>H2</summary><code>UPDATE … WHERE id = (SELECT id … ORDER BY … LIMIT 1 FOR UPDATE SKIP LOCKED) RETURNING id</code>.</details>
<details><summary>H3</summary>Điều kiện subquery: <code>status = 'queued' AND run_at &lt;= now()</code>; <code>ORDER BY priority DESC, run_at, id</code>.</details>

## ex02 · Nhận theo lô
<details><summary>H1</summary>Giống ex01 nhưng subquery trả nhiều dòng.</details>
<details><summary>H2</summary>Đổi <code>=</code> thành <code>IN</code>, <code>LIMIT 3</code>.</details>
<details><summary>H3</summary>Giữ nguyên <code>FOR UPDATE SKIP LOCKED</code> ở cuối subquery.</details>

## ex03 · Retry và dead-letter
<details><summary>H1</summary>Cột <code>attempts</code> đã được cộng lúc nhận job. So nó với <code>max_attempts</code>.</details>
<details><summary>H2</summary>Hai <code>CASE</code>: một cho <code>status</code>, một cho <code>run_at</code>. Backoff: <code>interval '10 seconds' * power(2, attempts)</code>.</details>
<details><summary>H3</summary>Nhánh hết lượt thử không cần đổi <code>run_at</code>; nhớ đặt <code>locked_at</code> và <code>locked_by</code> về NULL cho cả hai nhánh.</details>

## ex04 · Thu hồi job treo
<details><summary>H1</summary>Thời điểm worker nhận job nằm ở cột nào?</details>
<details><summary>H2</summary><code>WHERE status = 'running' AND locked_at &lt; now() - interval '5 minutes'</code>.</details>
<details><summary>H3</summary>Phân nhánh bằng <code>CASE WHEN attempts &gt;= max_attempts THEN 'dead' ELSE 'queued' END</code>.</details>

## ex05 · Hai worker không chờ nhau
<details><summary>H1</summary>Điều gì xảy ra với worker B khi dòng nó định chọn đang bị khóa bởi A?</details>
<details><summary>H2</summary>Có ba lựa chọn: không khóa, khóa và chờ, khóa và bỏ qua dòng bị khóa.</details>
<details><summary>H3</summary>Cuối subquery: <code>FOR UPDATE SKIP LOCKED</code>.</details>

## ex06 · Ba worker
<details><summary>H1</summary>Cùng câu như ex05. Điều quan trọng là mỗi worker chỉ nhận job mà không ai đang giữ.</details>
<details><summary>H2</summary>Câu của bạn phải trả đúng 1 cột <code>id</code> và trả NULL (không dòng) khi hết job sẵn sàng.</details>
<details><summary>H3</summary>Nếu worker thấy NULL sớm trong khi còn job: có thể do các job còn lại đang bị worker khác khóa (bình thường) hoặc điều kiện <code>status</code>/<code>run_at</code> sai.</details>

## ex07 · NOTIFY
<details><summary>H1</summary><code>pg_notify(channel, payload)</code> gọi được từ trigger.</details>
<details><summary>H2</summary>Cửa sổ 1: <code>LISTEN r04n_jobs;</code> rồi chạy một lệnh bất kỳ (psql chỉ in thông báo sau mỗi lệnh). Cửa sổ 2: <code>INSERT</code>, <code>BEGIN … ROLLBACK</code>, <code>BEGIN … COMMIT</code>.</details>
<details><summary>H3</summary>Để thử "worker đến muộn": chèn job trước, rồi mới <code>LISTEN</code>.</details>

## ex08 · Câu hỏi quy mô
<details><summary>H1</summary>Điều kiện <code>status = 'queued'</code> có nằm trong index không?</details>
<details><summary>H2</summary>Đọc <code>Buffers</code> của Index Scan. Index đúng thứ tự nhưng chứa cả job <code>done</code> thì phải bỏ qua từng dòng.</details>
<details><summary>H3</summary>Partial index chỉ chứa job đang chờ nên nhỏ và không phụ thuộc N.</details>
