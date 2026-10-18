# O06 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint.

## ex01
<details><summary>H1</summary>Kiểu <code>pg_lsn</code> trừ trực tiếp được, nhưng hàm chuyên dụng rõ nghĩa hơn: <code>pg_wal_lsn_diff(a, b)</code> trả <code>a − b</code> theo byte.</details>
<details><summary>H2</summary>Ba chặng: <code>sent → flush</code> (truyền), <code>flush → replay</code> (áp dụng), tổng <code>sent → replay</code>. Thứ tự: tổng giảm dần rồi tên.</details>
<details><summary>H3</summary><code>pg_wal_lsn_diff(sent_lsn, flush_lsn)</code>, <code>pg_wal_lsn_diff(flush_lsn, replay_lsn)</code>, <code>pg_wal_lsn_diff(sent_lsn, replay_lsn)</code>; <code>ORDER BY total_lag_bytes DESC, replica</code>.</details>

## ex02
<details><summary>H1</summary>Ba trạng thái, kiểm theo thứ tự ưu tiên: không streaming trước, rồi mới tới lag.</details>
<details><summary>H2</summary>So sánh với <code>NULL</code> cho kết quả <code>NULL</code> (không phải false). <code>replay_lag &gt; interval '5 seconds'</code> với replica nhàn rỗi là <code>NULL</code>; dùng <code>CASE</code> theo thứ tự để nó rơi xuống <code>OK</code>, hoặc <code>coalesce</code>.</details>
<details><summary>H3</summary><code>CASE WHEN state &lt;&gt; 'streaming' THEN 'NOT_STREAMING' WHEN pg_wal_lsn_diff(sent_lsn, replay_lsn) &gt; 16777216 OR replay_lag &gt; interval '5 seconds' THEN 'LAGGING' ELSE 'OK' END</code>.</details>

## ex03
<details><summary>H1</summary>So sánh hai giá trị <code>pg_lsn</code> bằng toán tử thường, <b>không</b> ép sang text.</details>
<details><summary>H2</summary>Cần giữ cả người chưa ghi (<code>NULL</code>) lẫn người không có replica đủ mới: dùng <code>LEFT JOIN</code> hoặc subquery tương quan, không phải <code>INNER JOIN</code>.</details>
<details><summary>H3</summary>Đếm bằng <code>(SELECT count(*) FROM o06.replicas_now r WHERE s.last_write_lsn IS NULL OR r.replay_lsn &gt;= s.last_write_lsn)</code>, rồi <code>CASE WHEN n &gt; 0 THEN 'replica' ELSE 'primary' END</code>.</details>

## ex04
<details><summary>H1</summary>Cần ba thứ trên primary: một role có <code>REPLICATION</code>, một dòng <code>pg_hba.conf</code> kiểu <code>host replication …</code>, và <code>pg_reload_conf()</code>.</details>
<details><summary>H2</summary><code>pg_basebackup</code> chạy <b>trong container replica</b> trước khi Postgres khởi động, ghi thẳng vào <code>$PGDATA</code>; sau đó <code>exec docker-entrypoint.sh postgres</code>.</details>
<details><summary>H3</summary><code>-R</code> tạo <code>standby.signal</code> và <code>primary_conninfo</code>; <code>-X stream</code> nhận WAL song song với việc sao chép; <code>-C -S replica1</code> tạo slot để primary giữ WAL.</details>

## ex05
<details><summary>H1</summary><code>SELECT pg_wal_replay_pause()</code> trên replica; <code>pg_is_wal_replay_paused()</code> để kiểm tra; <code>pg_wal_replay_resume()</code> để tiếp tục.</details>
<details><summary>H2</summary>Sau khi commit trên primary, lấy <code>pg_current_wal_lsn()</code>; trên replica so <code>pg_last_wal_replay_lsn() &gt;= '…'::pg_lsn</code>.</details>
<details><summary>H3</summary>Ba cách: đọc primary sau khi ghi, token LSN, <code>synchronous_commit = remote_apply</code>. So về độ chính xác, tải dồn về primary, và độ trễ mỗi commit.</details>

## ex06
<details><summary>H1</summary>Dừng primary (<code>docker stop</code>), <code>SELECT pg_promote()</code> trên replica. Timeline đọc từ tên file WAL: <code>left(pg_walfile_name(pg_current_wal_lsn()), 8)</code>.</details>
<details><summary>H2</summary>Primary cũ phải được dừng sạch rồi chạy <code>pg_rewind --source-server=… --write-recovery-conf</code> (cần data checksums hoặc <code>wal_log_hints</code>; PG18 bật checksums mặc định).</details>
<details><summary>H3</summary>Sau khi khởi động lại nếu không stream được, đọc log của standby: thường là thiếu dòng <code>pg_hba.conf</code> cho replication và thiếu slot trên primary mới (slot không được sao chép).</details>

## ex07
<details><summary>H1</summary>Publisher cần <code>wal_level = logical</code> (restart). <code>CREATE PUBLICATION p FOR TABLE …</code>; subscriber <code>CREATE SUBSCRIPTION s CONNECTION '…' PUBLICATION p</code>, bảng phải tạo sẵn ở subscriber.</details>
<details><summary>H2</summary>Theo dõi <code>pg_stat_subscription</code> và log subscriber; trên publisher xem <code>pg_replication_slots</code>: <code>pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)</code> là lượng WAL bị giữ.</details>
<details><summary>H3</summary>DDL phải áp dụng ở <b>cả hai</b> phía (subscriber trước khi publisher bắt đầu gửi dữ liệu dùng cột mới); thiếu khóa thì <code>ALTER TABLE … REPLICA IDENTITY FULL</code> hoặc thêm khóa chính.</details>

## ex08
<details><summary>H1</summary>Lag byte phụ thuộc tốc độ sinh WAL so với tốc độ replay, không phụ thuộc độ trễ mạng; lag <b>thời gian</b> thì cộng thêm độ trễ mạng.</details>
<details><summary>H2</summary>Xung đột replay chờ tối đa <code>max_standby_streaming_delay</code> rồi hủy truy vấn; <code>hot_standby_feedback</code> đổi "bị hủy" lấy "primary không dọn được".</details>
<details><summary>H3</summary>Với 80 ms mạng: <code>write_lag</code>/<code>flush_lag</code> tăng ≥ 80 ms; <code>remote_apply</code> mỗi commit thêm ít nhất một RTT; số byte WAL và khối lượng replay không đổi.</details>
