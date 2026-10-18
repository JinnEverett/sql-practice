# P10a · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.*`.

## ex01 · Plan theo selectivity
<details><summary>H1</summary>Chạy <code>EXPLAIN</code> (không ANALYZE) cho từng query; rất nhanh.</details>
<details><summary>H2</summary><code>u</code> không tương quan: Bitmap tới khoảng một nửa bảng. <code>ts</code> tương quan 1: Index Scan tới khoảng 60%.</details>
<details><summary>H3</summary>Bitmap, Bitmap, Seq Scan, Index Scan, Seq Scan.</details>

## ex02 · Sweep selectivity
<details><summary>H1</summary>Buffers của Bitmap Heap Scan tỉ lệ với số page có ít nhất một dòng khớp.</details>
<details><summary>H2</summary>Mỗi page chứa ~100 dòng; khi lấy ≥ 1% dòng ngẫu nhiên, hầu như page nào cũng có một dòng khớp.</details>
<details><summary>H3</summary>Hòa vốn thời gian giữa Bitmap và Seq Scan dịch về selectivity thấp hơn khi N tăng.</details>

## ex03 · Điểm gãy của join
<details><summary>H1</summary>Nested Loop lặp theo số dòng ngoài; Hash Join đọc cả bảng trong một lần.</details>
<details><summary>H2</summary>Giao điểm nằm trong khoảng vài chục nghìn dòng ngoài.</details>
<details><summary>H3</summary>Nested Loop, Nested Loop, Hash Join, Hash Join.</details>

## ex04 · Sort cần bao nhiêu bộ nhớ
<details><summary>H1</summary>Thử <code>SET work_mem</code> và xem <code>temp written</code> trong <code>EXPLAIN (ANALYZE, BUFFERS)</code>; tắt parallel.</details>
<details><summary>H2</summary>Tìm nhị phân giữa 4 MB (tràn) và 64 MB (đủ).</details>
<details><summary>H3</summary>Ngưỡng là 46 MB.</details>

## ex05 · Tràn bộ nhớ
<details><summary>H1</summary>Tràn ghi file tạm, nhưng file tạm nằm trong page cache của OS.</details>
<details><summary>H2</summary>Sort/hash trong bộ nhớ nhỏ có thể thân thiện với cache CPU hơn bộ nhớ lớn.</details>
<details><summary>H3</summary>Nhìn cột <code>temp_blocks</code> và so thời gian giữa 4MB / 64MB / 1GB.</details>

## ex06 · Bảng vượt shared_buffers
<details><summary>H1</summary>Seq Scan bảng lớn dùng ring buffer riêng.</details>
<details><summary>H2</summary><code>SELECT count(*) FROM pg_buffercache WHERE relfilenode = pg_relation_filenode('p10.t_m'::regclass)</code>.</details>
<details><summary>H3</summary>Bitmap Heap Scan không dùng ring buffer: nó làm đầy cache, nhưng nếu số page > số buffer thì lần hai vẫn đọc lại.</details>

## ex07 · O(n) hay O(log n)
<details><summary>H1</summary>Phân loại từng query: chạm số page hằng hay tỉ lệ N?</details>
<details><summary>H2</summary>Có index: <code>id = …</code>, <code>max(u)</code>, top-10 theo <code>u</code> đều đọc vài page.</details>
<details><summary>H3</summary><code>count(*)</code>, <code>max(amount)</code>, top-10 theo <code>amount</code> phải quét cả bảng.</details>

## ex08 · Danh sách mới nhất của nhóm cũ
<details><summary>H1</summary>Planner tin các dòng khớp rải đều theo <code>ts</code>; thực tế chúng nằm hết ở đầu. Đọc ngược index thì phải đi gần hết bảng.</details>
<details><summary>H2</summary>Cần lọc <code>gen</code> trước (có index) rồi mới sắp xếp, và phải buộc planner làm theo thứ tự đó.</details>
<details><summary>H3</summary><code>CREATE INDEX ON p10.t_m (gen);</code> rồi <code>WITH f AS MATERIALIZED (SELECT id, ts FROM p10.t_m WHERE gen &lt; 5000) SELECT id, ts FROM f ORDER BY ts DESC LIMIT 20</code>.</details>
