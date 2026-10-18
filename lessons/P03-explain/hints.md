# P03 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Seq Scan song song
<details><summary>H1</summary><code>actual rows</code> là số dòng <b>mỗi loop</b>. Có bao nhiêu loop ở Parallel Seq Scan?</details>
<details><summary>H2</summary>Tổng = <code>actual rows × loops</code>. Đối chiếu bằng <code>count(*) FILTER (WHERE …)</code> trên <code>p03.o</code>.</details>
<details><summary>H3</summary><code>buffers</code> = số page của bảng: <code>pg_relation_size('p03.o') / 8192</code>.</details>

## ex02 · Index Scan hay Bitmap?
<details><summary>H1</summary>Cột <code>correlation</code> của <code>pg_stats</code> nói thứ tự cột có khớp thứ tự vật lý của heap không.</details>
<details><summary>H2</summary><code>SELECT attname, correlation FROM pg_stats WHERE schemaname='p03' AND tablename='o'</code>; dùng <code>abs()</code> vì dấu âm = ngược thứ tự.</details>
<details><summary>H3</summary>Correlation ≈ 1 → Index Scan (đọc heap tuần tự); ≈ 0 → Bitmap Heap Scan.</details>

## ex03 · Nested Loop và loops
<details><summary>H1</summary>Node phía trong của Nested Loop chạy <code>loops</code> lần, mỗi lần cho <code>rows</code> dòng.</details>
<details><summary>H2</summary><code>outer_rows = count(*) FROM p03.u WHERE id &lt;= 5</code>; <code>rows_returned = count(*)</code> của join.</details>
<details><summary>H3</summary><code>rows_returned = loops × rows_per_loop</code>; <code>Heap Blocks: exact=100</code> cho <code>heap_blocks</code>.</details>

## ex04 · Hash Join và batch
<details><summary>H1</summary>Dưới node <code>Hash</code> là bảng được băm vào bộ nhớ.</details>
<details><summary>H2</summary><code>Batches: 1</code> = trong RAM; &gt; 1 = chia ra đĩa. Số batch tăng khi <code>work_mem</code> giảm.</details>
<details><summary>H3</summary>Phía quét (<code>o</code>, 400 000 dòng) cũng bị chia ra file tạm theo batch, nên temp page nhiều hơn hẳn bảng <code>u</code>.</details>

## ex05 · Sort tràn đĩa
<details><summary>H1</summary>Cùng dữ liệu, nhưng RAM dùng nhiều hơn đĩa vì cấu trúc tuple trong bộ nhớ.</details>
<details><summary>H2</summary>Thử <code>SET work_mem = '16MB'</code>, <code>'20MB'</code>… tìm giá trị nhỏ nhất cho ra <code>quicksort</code>. Tắt parallel để plan giống đề.</details>
<details><summary>H3</summary>Chia đôi khoảng tìm kiếm giữa 4MB (tràn) và 22MB (đủ). Kết quả 19.</details>

## ex06 · Cost thấp mà chạy chậm
<details><summary>H1</summary>Planner nhân xác suất của hai điều kiện như thể chúng độc lập.</details>
<details><summary>H2</summary><code>est_independent = N × (số dòng pending / N) × (số dòng amount=0 / N)</code>, đếm bằng <code>count(*) FILTER</code>.</details>
<details><summary>H3</summary>Hệ số lệch = 400 / 4 = 100. Thực tế <code>status</code> và <code>amount</code> có tương quan (pending là mọi <code>id</code> chia hết cho 100).</details>

## ex07 · Điểm gãy của planner
<details><summary>H1</summary><code>EXPLAIN SELECT id, amount FROM p03.o WHERE …</code> không chạy query nên rất nhanh.</details>
<details><summary>H2</summary>Với <code>created_at</code> (correlation 1) planner thích Index Scan khi lấy &lt; ~50% dòng; với <code>user_id</code> (correlation ~0) thích Bitmap tới ~50% rồi chuyển Seq Scan.</details>
<details><summary>H3</summary>Đáp án: <code>Bitmap Heap Scan, Bitmap Heap Scan, Seq Scan, Index Scan, Seq Scan</code>.</details>

## ex08 · EXPLAIN ANALYZE mà không đổi dữ liệu
<details><summary>H1</summary><code>EXPLAIN</code> thường không chạy; <code>EXPLAIN ANALYZE</code> thì chạy thật.</details>
<details><summary>H2</summary>Đặt lệnh trong một transaction và hủy nó sau khi xem plan.</details>
<details><summary>H3</summary><code>BEGIN; EXPLAIN ANALYZE UPDATE …; ROLLBACK;</code></details>

## ex09 · Plan đổi hình theo quy mô
<details><summary>H1</summary>Bảng lớn đủ để planner thấy lợi khi chia việc cho nhiều worker.</details>
<details><summary>H2</summary>So Hash Join ở các scale, chú ý chữ <code>Parallel</code> và <code>Gather Merge</code>.</details>
<details><summary>H3</summary>Dùng <code>bench/bench.sh</code> với <code>--scales xs,s,m</code>; so cost từ <code>EXPLAIN</code> với thời gian đo.</details>
