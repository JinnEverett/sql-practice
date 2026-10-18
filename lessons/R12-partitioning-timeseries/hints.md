# R12 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Partition theo tháng
<details><summary>H1</summary>Bảng cha khai báo <code>PARTITION BY RANGE (ts)</code>; mỗi tháng một <code>CREATE TABLE … PARTITION OF … FOR VALUES FROM … TO …</code>.</details>
<details><summary>H2</summary>Khoảng nửa mở: <code>FROM ('2026-01-01 00:00+00') TO ('2026-02-01 00:00+00')</code>; partition default: <code>PARTITION OF … DEFAULT</code>.</details>
<details><summary>H3</summary>PK phải chứa khóa partition: <code>PRIMARY KEY (device_id, ts)</code>. <code>PRIMARY KEY (device_id)</code> báo lỗi 0A000.</details>

## ex02 · Pruning
<details><summary>H1</summary>Điều kiện phải so sánh trực tiếp cột <code>ts</code> với hằng. Hàm bọc quanh <code>ts</code> làm mất pruning.</details>
<details><summary>H2</summary>Tháng 3 giờ VN = <code>[2026-03-01 00:00+07, 2026-04-01 00:00+07)</code>: viết đúng hai hằng này với <code>&gt;=</code> và <code>&lt;</code>.</details>
<details><summary>H3</summary>Khoảng này giao với 2 partition UTC (tháng 2 và tháng 3). Kiểm tra bằng <code>EXPLAIN</code>: chỉ thấy <code>events_p_2026_02</code> và <code>events_p_2026_03</code>.</details>

## ex03 · LIST
<details><summary>H1</summary><code>PARTITION BY LIST (region)</code>, mỗi partition <code>FOR VALUES IN ('north')</code>.</details>
<details><summary>H2</summary>PK phải chứa <code>region</code> nên là <code>(order_id, region)</code>. Hệ quả: cùng <code>order_id</code> ở hai region khác nhau vẫn hợp lệ.</details>
<details><summary>H3</summary>Partition hứng phần còn lại: <code>PARTITION OF … DEFAULT</code>.</details>

## ex04 · HASH
<details><summary>H1</summary><code>PARTITION BY HASH (tenant_id)</code>; mỗi partition <code>FOR VALUES WITH (MODULUS 4, REMAINDER r)</code>.</details>
<details><summary>H2</summary>Cần đủ 4 remainder 0, 1, 2, 3 thì mọi giá trị đều có chỗ.</details>
<details><summary>H3</summary>PK <code>(tenant_id, id)</code> chứa khóa partition. Điều kiện <code>tenant_id = 7</code> cắt tỉa còn 1 partition.</details>

## ex05 · Retention
<details><summary>H1</summary>Xóa nguyên partition, không xóa từng dòng.</details>
<details><summary>H2</summary><code>ALTER TABLE r12.events_p DETACH PARTITION r12.events_p_2026_01;</code> rồi xóa bảng vừa tách.</details>
<details><summary>H3</summary>Lặp cho các tháng 01, 02, 03: mỗi tháng một cặp <code>DETACH PARTITION</code> + <code>DROP TABLE</code>.</details>

## ex06 · Attach không quét
<details><summary>H1</summary>ATTACH chỉ bỏ qua bước quét nếu bảng đã có ràng buộc chứng minh mọi dòng thuộc khoảng.</details>
<details><summary>H2</summary><code>ADD CONSTRAINT … CHECK (ts &gt;= … AND ts &lt; …) NOT VALID</code> → <code>VALIDATE CONSTRAINT</code> → <code>ATTACH PARTITION … FOR VALUES FROM … TO …</code>.</details>
<details><summary>H3</summary>Sau khi gắn, <code>DROP CONSTRAINT</code> của CHECK (đã thừa vì khoảng partition làm đúng việc đó).</details>

## ex07 · Rollup
<details><summary>H1</summary>Cần upsert: chèn nếu chưa có, ghi đè nếu đã có.</details>
<details><summary>H2</summary><code>INSERT … SELECT … GROUP BY sensor, (ts AT TIME ZONE 'Asia/Ho_Chi_Minh')::date ON CONFLICT (sensor, day) DO UPDATE SET …</code>.</details>
<details><summary>H3</summary>Dùng <code>EXCLUDED.n</code>, <code>EXCLUDED.sum_value</code>… (ghi đè, không cộng dồn vào số cũ). Lọc <code>ts &gt;= '2026-03-01 00:00+07' AND ts &lt; '2026-03-04 00:00+07'</code>.</details>

## ex08 · ensure_month
<details><summary>H1</summary>Cần ranh giới đầu tháng và đầu tháng sau từ <code>p_day</code>.</details>
<details><summary>H2</summary><code>date_trunc('month', p_day)</code> và <code>+ interval '1 month'</code> (đúng cả tháng 12). <code>CREATE TABLE IF NOT EXISTS … PARTITION OF …</code> bằng <code>EXECUTE format(…)</code> với <code>%I</code> và <code>%L</code>.</details>
<details><summary>H3</summary>Tên: <code>'events_p_' || to_char(d0, 'YYYY_MM')</code>; ranh giới UTC: <code>d0::text || ' 00:00+00'</code>.</details>

## ex09 · Câu hỏi quy mô
<details><summary>H1</summary>Pruning có ích gì khi đã có index phù hợp?</details>
<details><summary>H2</summary>Đếm số partition trong plan và <code>Planning Time</code> khi số partition tăng.</details>
<details><summary>H3</summary>Retention: <code>DELETE</code> ghi dead tuple + WAL cho từng dòng; <code>DETACH + DROP</code> chỉ đổi catalog.</details>
