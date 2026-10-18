# P04 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Đọc pg_stats
<details><summary>H1</summary><code>pg_stats</code> có <code>most_common_vals</code> và <code>histogram_bounds</code> kiểu <code>anyarray</code> (NULL nếu không có).</details>
<details><summary>H2</summary>Cast <code>::text::text[]</code> rồi <code>array_length(…, 1)</code>, bọc <code>coalesce(…, 0)</code>.</details>
<details><summary>H3</summary><code>n_distinct &lt; 0</code> là tỉ lệ so với số dòng; histogram chỉ lập cho phần KHÔNG nằm trong MCV.</details>

## ex02 · Tự tính số dòng ước lượng
<details><summary>H1</summary>MCV: mỗi giá trị trong <code>most_common_vals</code> có tần suất tương ứng ở cùng vị trí trong <code>most_common_freqs</code>.</details>
<details><summary>H2</summary><code>unnest(most_common_vals::text::text[], most_common_freqs)</code> trong <code>FROM</code>; nhân với <code>reltuples</code> của <code>pg_class</code>.</details>
<details><summary>H3</summary>Số thực tế bằng <code>GROUP BY status</code> trên bảng; ghép hai bên theo <code>status</code>.</details>

## ex03 · Mới nạp xong
<details><summary>H1</summary>Planner đang dùng thống kê của lần ANALYZE cũ.</details>
<details><summary>H2</summary>Có một lệnh thu thập lại thống kê cột. <code>VACUUM</code> thường không làm việc đó.</details>
<details><summary>H3</summary><code>ANALYZE p04.job;</code></details>

## ex04 · Tag lệch
<details><summary>H1</summary>Danh sách MCV tối đa bằng "statistics target" của cột; mặc định 100 và tag 180 nằm ngoài top 100.</details>
<details><summary>H2</summary><code>ALTER TABLE … ALTER COLUMN … SET STATISTICS n</code> rồi thu thập lại.</details>
<details><summary>H3</summary><code>SET STATISTICS 300</code> (hoặc 1000) cho <code>tag</code>, sau đó <code>ANALYZE p04.tag_event;</code></details>

## ex05 · Thành phố và mã bưu điện
<details><summary>H1</summary>Planner nhân xác suất <code>city</code> và <code>zip</code> như thể độc lập; nhưng <code>zip</code> xác định <code>city</code>.</details>
<details><summary>H2</summary><code>CREATE STATISTICS … (dependencies) ON … FROM …</code>; sau đó cần <code>ANALYZE</code>.</details>
<details><summary>H3</summary><code>CREATE STATISTICS addr_dep (dependencies) ON city, zip FROM p04.addr; ANALYZE p04.addr;</code></details>

## ex06 · Báo cáo sáng nào cũng chậm
<details><summary>H1</summary>Hai việc: thu thập lại ngay, và cấu hình để lần sau tự chạy sớm hơn.</details>
<details><summary>H2</summary>Reloption per-table: <code>autovacuum_analyze_scale_factor</code> và <code>autovacuum_enabled</code>.</details>
<details><summary>H3</summary><code>ANALYZE p04.log; ALTER TABLE p04.log SET (autovacuum_enabled = true, autovacuum_analyze_scale_factor = 0.01);</code></details>

## ex07 · GROUP BY dùng quá nhiều RAM
<details><summary>H1</summary>Số nhóm ước lượng = tích số giá trị khác nhau của từng cột. Cần thống kê cho <b>tổ hợp</b> cột.</details>
<details><summary>H2</summary>Một loại extended statistics nói về số giá trị khác nhau của tổ hợp.</details>
<details><summary>H3</summary><code>CREATE STATISTICS fact_nd (ndistinct) ON a, b FROM p04.fact; ANALYZE p04.fact;</code></details>

## ex08 · ANALYZE ở 10k, 1M, 10M
<details><summary>H1</summary>Mẫu ANALYZE là <code>300 × target</code> dòng cố định, không phụ thuộc N.</details>
<details><summary>H2</summary>Chi phí đọc mẫu: tối đa 30 000 page ngẫu nhiên; bảng 10k dòng chỉ 120 page nên đọc hết.</details>
<details><summary>H3</summary>Ngưỡng autovacuum ANALYZE = 50 + 0.1 × reltuples.</details>
