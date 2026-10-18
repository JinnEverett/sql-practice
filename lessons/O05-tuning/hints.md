# O05 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint.

## ex01
<details><summary>H1</summary><code>pg_settings.setting</code> là text và có cột <code>unit</code> (8kB, kB, MB…): không thể so trực tiếp.</details>
<details><summary>H2</summary><code>current_setting('work_mem')</code> trả chuỗi có đơn vị (vd. <code>4MB</code>). <code>pg_size_bytes(text)</code> đổi sang byte.</details>
<details><summary>H3</summary><code>round(pg_size_bytes(current_setting(name)) / 1048576.0, 1)</code>, lọc <code>name IN (…)</code> từ <code>pg_settings</code>, <code>ORDER BY name</code>.</details>

## ex02
<details><summary>H1</summary><code>pg_class</code> có <code>relpages</code> và <code>reltuples</code>. Hằng số cost lấy từ <code>current_setting('seq_page_cost')</code> và <code>current_setting('cpu_tuple_cost')</code> (text, ép sang numeric).</details>
<details><summary>H2</summary>Cost Seq Scan không có điều kiện lọc = số trang × <code>seq_page_cost</code> + số dòng × <code>cpu_tuple_cost</code>. Không có <code>random_page_cost</code> ở đây.</details>
<details><summary>H3</summary><code>WHERE oid = 'o05.items'::regclass</code>; <code>reltuples::bigint</code>; <code>round(relpages * current_setting('seq_page_cost')::numeric + reltuples * current_setting('cpu_tuple_cost')::numeric, 2)</code>. So với <code>EXPLAIN (FORMAT JSON)</code> để chắc.</details>

## ex03
<details><summary>H1</summary><code>EXPLAIN (ANALYZE)</code> của node Sort in <code>Sort Method: external merge Disk: …</code> khi tràn, <code>quicksort Memory: …</code> khi vừa.</details>
<details><summary>H2</summary>Dung lượng đĩa tạm (≈ 46 MB) <b>nhỏ hơn</b> bộ nhớ cần để sort trong RAM, vì tuple trong RAM có thêm chi phí quản lý. Thử vài mốc: 64MB, 96MB, 128MB.</details>
<details><summary>H3</summary><code>SET LOCAL work_mem = '128MB';</code> (bất kỳ mốc nào đủ và ≤ 256MB đều được chấm đúng).</details>

## ex04
<details><summary>H1</summary>Ép loại scan: <code>SET LOCAL enable_seqscan = off</code> (và tương tự <code>enable_bitmapscan</code>, <code>enable_indexscan</code>). Làm trong transaction rồi <code>ROLLBACK</code>.</details>
<details><summary>H2</summary>Bảng không tương quan: <code>k = (random()*1000000)::int</code>. <code>ANALYZE</code> sau khi tạo index. Chạy cùng truy vấn nhiều lần, lấy lần nhanh nhất để loại nhiễu cache.</details>
<details><summary>H3</summary>Độ chọn lọc 0,1%, 1%, 5%, 20%, 50%, 80% ứng với <code>X</code> = 1000, 10000, 50000, 200000, 500000, 800000 trên 1 triệu giá trị đều. Chú ý hàng 20% và 50%.</details>

## ex05
<details><summary>H1</summary><code>pg_stat_checkpointer</code>: <code>num_timed</code> (hết <code>checkpoint_timeout</code>) và <code>num_requested</code> (WAL đầy).</details>
<details><summary>H2</summary><code>max_wal_size</code> có context <code>sighup</code>: <code>ALTER SYSTEM SET …</code> rồi <code>SELECT pg_reload_conf()</code>, không cần restart.</details>
<details><summary>H3</summary>Phía 4GB chưa phải trả checkpoint nào trong 60 s vì chưa chạm <code>checkpoint_timeout</code> (5 phút). Cái giá: thời gian phục hồi sau crash và dung lượng WAL.</details>

## ex06
<details><summary>H1</summary>Trường hợp xấu nhất = <code>work_mem</code> × số node cần bộ nhớ × số kết nối (× parallel worker).</details>
<details><summary>H2</summary>Mỗi <code>Sort</code> trong plan có dòng <code>Sort Method: … Memory: …kB</code>; cộng các dòng đó lại. Tắt parallel (<code>max_parallel_workers_per_gather = 0</code>) để đo sạch.</details>
<details><summary>H3</summary>Đặt theo phạm vi hẹp: <code>SET LOCAL work_mem</code> trong transaction của báo cáo, hoặc <code>ALTER ROLE report SET work_mem</code>; giữ giá trị toàn cục thấp.</details>

## ex07
<details><summary>H1</summary><code>shared_buffers</code> cần restart; <code>max_wal_size</code> và <code>synchronous_commit</code> chỉ cần reload.</details>
<details><summary>H2</summary>Làm nóng 10 s trước khi đo; reset <code>pg_stat_reset_shared('checkpointer')</code>; mỗi bước đo cùng một lệnh pgbench.</details>
<details><summary>H3</summary><code>synchronous_commit=off</code> mất tối đa vài trăm ms giao dịch đã báo thành công khi crash, dữ liệu vẫn nhất quán. <code>fsync=off</code> có thể làm hỏng cả cụm.</details>

## ex08
<details><summary>H1</summary>Tỉ lệ hit = Δ<code>blks_hit</code> / (Δ<code>blks_hit</code> + Δ<code>blks_read</code>) trong <code>pg_stat_database</code>, lấy hiệu hai thời điểm.</details>
<details><summary>H2</summary>Một "read" của Postgres có thể được OS phục vụ từ page cache, rẻ hơn nhiều so với đọc đĩa thật.</details>
<details><summary>H3</summary>Giới hạn bộ nhớ container làm page cache nhỏ lại (cgroup tính cả page cache), nên hit/read của Postgres mới quan trọng hơn.</details>
