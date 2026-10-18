# P07 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Các phiên bản của một dòng
<details><summary>H1</summary><code>pageinspect</code> có hàm đọc page thô và liệt kê tuple.</details>
<details><summary>H2</summary><code>heap_page_items(get_raw_page('p07.ver', 0))</code> trả về <code>lp, t_xmax, t_ctid, t_infomask2</code>…</details>
<details><summary>H3</summary><code>t_xmax &lt;&gt; 0</code> cho <code>has_xmax</code>; <code>(t_infomask2 &amp; 16384) &lt;&gt; 0</code> cho HOT_UPDATED, <code>32768</code> cho HEAP_ONLY.</details>

## ex02 · Dọn mà không khóa
<details><summary>H1</summary>Hai lệnh dọn khác nhau ở khóa giữ và việc có trả file hay không.</details>
<details><summary>H2</summary>Lệnh thường chỉ giữ khóa không chặn đọc/ghi và không co file.</details>
<details><summary>H3</summary><code>VACUUM p07.bloat;</code></details>

## ex03 · Đo bloat
<details><summary>H1</summary>Extension <code>pgstattuple</code> đếm chính xác tuple sống/chết và chỗ trống.</details>
<details><summary>H2</summary><code>SELECT … FROM pgstattuple('p07.bloat')</code>: <code>table_len, tuple_count, dead_tuple_count, tuple_percent</code>.</details>
<details><summary>H3</summary><code>table_len / 8192</code> cho số page; <code>round(100 - tuple_percent)</code> cho % lãng phí.</details>

## ex04 · Thu nhỏ file
<details><summary>H1</summary>Muốn file co lại, bảng phải được ghi lại sang file mới.</details>
<details><summary>H2</summary>Hai lệnh làm được: một cái gọn lại theo chỗ trống, một cái còn sắp lại theo index.</details>
<details><summary>H3</summary><code>VACUUM FULL p07.bloat;</code> hoặc <code>CLUSTER p07.bloat USING bloat_pkey;</code></details>

## ex05 · VACUUM chạy rồi mà dead tuple vẫn còn
<details><summary>H1</summary>Tìm session đang giữ snapshot cũ: <code>pg_stat_activity.backend_xmin</code>.</details>
<details><summary>H2</summary>Lọc theo <code>application_name</code> (hoặc <code>backend_xmin IS NOT NULL</code> và khác pid của mình); rồi hủy hoặc kết thúc backend.</details>
<details><summary>H3</summary><code>SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE application_name = 'p07_report';</code></details>

## ex06 · Anti-wraparound
<details><summary>H1</summary><code>VACUUM</code> thường chỉ freeze tuple đủ già (<code>vacuum_freeze_min_age</code>). Có tùy chọn ép freeze mọi thứ.</details>
<details><summary>H2</summary><code>VACUUM (FREEZE) bảng;</code></details>
<details><summary>H3</summary>Kiểm: <code>SELECT * FROM pg_visibility_map_summary('p07.hist')</code> → <code>all_frozen</code> bằng số page.</details>

## ex07 · Hàng đợi 20 triệu dòng
<details><summary>H1</summary>Ngưỡng = <code>threshold + scale_factor × reltuples</code>; bảng lớn thì scale_factor mặc định 0.2 quá cao.</details>
<details><summary>H2</summary><code>ALTER TABLE … SET (autovacuum_enabled = true, autovacuum_vacuum_scale_factor = …, autovacuum_vacuum_threshold = …)</code>.</details>
<details><summary>H3</summary><code>scale_factor = 0.005</code> và <code>threshold = 1000</code>: 1 000 + 0.005 × 20 000 000 = 101 000 ≤ 150 000.</details>

## ex08 · Bloat và VACUUM theo N
<details><summary>H1</summary>Mỗi UPDATE toàn bảng tạo thêm một bản sao của mọi dòng. Pruning và VACUUM cho phép dùng lại chỗ.</details>
<details><summary>H2</summary>Tạo bảng tạm <code>CREATE TABLE scratch AS SELECT * FROM orders</code> rồi đo <code>pg_relation_size</code> sau từng bước.</details>
<details><summary>H3</summary>VACUUM đưa chỗ chết vào free space map nên UPDATE kế tiếp không làm file lớn thêm nhiều.</details>
