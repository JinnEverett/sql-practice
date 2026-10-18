# O04 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint.

## ex01
<details><summary>H1</summary>Bảng <code>pg_settings</code> có cột <code>name</code> và <code>setting</code> (dạng text).</details>
<details><summary>H2</summary>Có <b>hai</b> tham số "dành riêng" cần trừ, không chỉ một: <code>superuser_reserved_connections</code> và <code>reserved_connections</code>.</details>
<details><summary>H3</summary>Ba subquery <code>SELECT setting::int FROM pg_settings WHERE name = '…'</code>, lấy cái đầu trừ hai cái sau, đặt tên cột <code>usable_connections</code>.</details>

## ex02
<details><summary>H1</summary>Tổng của một dịch vụ = <code>instances * pool_size</code>. Tổng cộng dồn cần window function.</details>
<details><summary>H2</summary><code>sum(total_conns) OVER (ORDER BY total_conns DESC)</code>. Giới hạn dùng được là 100 − 3 − 0.</details>
<details><summary>H3</summary>Một CTE tính <code>total_conns</code>, bên ngoài thêm <code>running_total</code> và <code>running_total &lt;= 97 AS fits</code>; <code>ORDER BY total_conns DESC</code>.</details>

## ex03
<details><summary>H1</summary>Hai nhóm điều kiện khác nhau theo <code>state</code>, mỗi nhóm một ngưỡng thời gian riêng.</details>
<details><summary>H2</summary>Trạng thái "aborted" có thêm hậu tố: <code>state LIKE 'idle in transaction%'</code>. Đừng dùng <code>LIKE 'idle%'</code> cho cả hai nhóm, nó nuốt luôn <code>idle</code> ngắn hạn. Loại <code>monitor</code> bằng <code>usename</code>.</details>
<details><summary>H3</summary><code>CASE WHEN state LIKE 'idle in transaction%' AND idle_s &gt; 60 THEN 'idle_in_tx' WHEN state = 'idle' AND idle_s &gt; 900 THEN 'idle_long' END AS reason</code> trong subquery, rồi lọc <code>reason IS NOT NULL AND usename &lt;&gt; 'monitor'</code>.</details>

## ex04
<details><summary>H1</summary><code>pgbench -C</code> mở kết nối mới cho từng giao dịch. Output có dòng <code>average connection time</code>.</details>
<details><summary>H2</summary>Để đi qua TCP thay vì unix socket, thêm <code>-h</code> tới địa chỉ server. Chạy pgbench từ container khác cùng mạng, hoặc dùng <code>-h 127.0.0.1</code> bên trong container.</details>
<details><summary>H3</summary>Hệ số chậm = tps(bền) / tps(<code>-C</code>). So thời gian mở kết nối với trễ trung bình của một truy vấn ở chế độ bền.</details>

## ex05
<details><summary>H1</summary>Cần ba con số: <code>max_client_conn</code> (≥ 320), <code>default_pool_size</code> hoặc <code>pool_size</code> của database (10), và <code>pool_mode = transaction</code>.</details>
<details><summary>H2</summary>PgBouncer cần <code>auth_file</code> (userlist) khớp với cách server xác thực (SCRAM). Console quản trị: DB ảo <code>pgbouncer</code>, lệnh <code>SHOW POOLS</code>, <code>SHOW STATS</code>.</details>
<details><summary>H3</summary>Container tạm cùng mạng với server; cài <code>pgbouncer</code>; trong <code>[databases]</code> trỏ tới <code>host=sql-practice-pg</code>; chạy <code>pgbouncer -d</code> bằng user không phải root (cần <code>pidfile</code>).</details>

## ex06
<details><summary>H1</summary>Đếm kết nối theo <code>state</code> và <code>application_name</code> trong <code>pg_stat_activity</code>. CPU thấp mà hết kết nối nghĩa là phần lớn kết nối đang <b>không làm gì</b>.</details>
<details><summary>H2</summary>Mỗi cách chữa khác nhau ở: có đụng ứng dụng không, có cần restart không, tác dụng phụ là gì.</details>
<details><summary>H3</summary>Thứ tự hợp lý: cắt <code>idle in transaction</code> (và đặt timeout) → giảm tổng pool của ứng dụng → PgBouncer → cuối cùng mới đến <code>max_connections</code>.</details>

## ex07
<details><summary>H1</summary>Pool nhỏ làm hai client dễ <b>dùng chung</b> một kết nối server. Thử <code>pool_size = 1</code> cho hai client nối tiếp nhau.</details>
<details><summary>H2</summary>Với <code>pool_size = 2</code>, giữ cả hai kết nối server bận bằng hai transaction dài rồi để client khác chạy <code>EXECUTE</code>.</details>
<details><summary>H3</summary>Sửa: <code>SET LOCAL</code> (hoặc đặt tham số ở cấp role), <code>pg_advisory_xact_lock</code>, prepared statement ở mức giao thức (<code>max_prepared_statements</code>) hoặc tắt prepare ở driver.</details>

## ex08
<details><summary>H1</summary>Thông lượng tăng theo số core đang thực sự chạy; sau đó chỉ còn xếp hàng.</details>
<details><summary>H2</summary>Truy vấn ghi tranh chấp khóa dòng (bảng <code>pgbench_branches</code> chỉ có 10 dòng ở scale 10), nên đường cong của nó khác select-only.</details>
<details><summary>H3</summary>Pool phục vụ 400 request đồng thời không cần 400 kết nối; hàng đợi ở pooler rẻ hơn hàng đợi bên trong server.</details>
