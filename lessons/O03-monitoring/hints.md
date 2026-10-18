# O03 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint.

## ex01
<details><summary>H1</summary>Cột <code>total_exec_time</code> của <code>pg_stat_statements</code> là tổng thời gian cộng dồn (ms).</details>
<details><summary>H2</summary>Loại câu lệnh của chính extension: <code>WHERE query NOT ILIKE '%pg_stat_statements%'</code>.</details>
<details><summary>H3</summary><code>round(total_exec_time::numeric, 1)</code>, <code>round(mean_exec_time::numeric, 2)</code>, <code>left(query, 80)</code>, <code>ORDER BY total_exec_time DESC LIMIT 5</code>.</details>

## ex02
<details><summary>H1</summary>Cột <code>shared_blks_hit</code> và <code>shared_blks_read</code>.</details>
<details><summary>H2</summary>Tổng block = hit + read; trung bình mỗi lần = tổng / <code>calls</code>.</details>
<details><summary>H3</summary><code>round((shared_blks_hit + shared_blks_read)::numeric / nullif(calls, 0), 1)</code>; sắp xếp theo tổng block, không phải <code>calls</code>.</details>

## ex03
<details><summary>H1</summary><code>pg_stat_user_tables</code> có <code>seq_scan</code>, <code>idx_scan</code>, <code>seq_tup_read</code>.</details>
<details><summary>H2</summary><code>idx_scan</code> NULL khi bảng không có index nào được dùng: dùng <code>coalesce</code>. Kích thước: <code>pg_relation_size(relid)</code>.</details>
<details><summary>H3</summary><code>WHERE schemaname = 'o03' AND pg_relation_size(relid) &gt; 10 * 1024 * 1024 AND seq_scan &gt; coalesce(idx_scan, 0)</code>.</details>

## ex04
<details><summary>H1</summary><code>pg_blocking_pids(pid)</code> trả mảng pid đang chặn.</details>
<details><summary>H2</summary>Nối <code>pg_stat_activity</code> với chính nó qua <code>unnest(pg_blocking_pids(blocked.pid))</code>.</details>
<details><summary>H3</summary>Xử lý idle in transaction: <code>pg_terminate_backend(pid)</code> cho phiên có <code>state = 'idle in transaction'</code> đã quá lâu; phòng ngừa bằng <code>idle_in_transaction_session_timeout</code>.</details>

## ex05
<details><summary>H1</summary><code>SET log_min_duration_statement = 200</code> ở mức session (superuser).</details>
<details><summary>H2</summary><code>LOAD 'auto_explain'</code> rồi <code>SET auto_explain.log_min_duration = 0</code>.</details>
<details><summary>H3</summary>Log ra stderr của server: <code>docker logs sql-practice-pg</code>.</details>

## ex06
<details><summary>H1</summary>Sắp theo <code>total_exec_time</code>, nhưng so sánh với <code>min/max_exec_time</code> trước khi tin <code>mean</code>.</details>
<details><summary>H2</summary>Chạy lại từng truy vấn bằng <code>EXPLAIN (ANALYZE, BUFFERS)</code> để thấy Seq Scan, số buffers.</details>
<details><summary>H3</summary>Đối chiếu <code>solutions/ex06.md</code> sau khi tự chẩn đoán.</details>

## ex07
<details><summary>H1</summary>Truy vấn càng nhẹ thì overhead cố định của giám sát càng lớn theo tỉ lệ.</details>
<details><summary>H2</summary><code>ALTER SYSTEM SET … ; SELECT pg_reload_conf();</code> và nhớ <code>ALTER SYSTEM RESET …</code> sau khi đo.</details>
<details><summary>H3</summary>Đối chiếu <code>solutions/ex07.md</code>.</details>
