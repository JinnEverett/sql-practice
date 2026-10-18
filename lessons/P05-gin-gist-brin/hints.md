# P05 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · jsonb
<details><summary>H1</summary>Toán tử <code>@&gt;</code> (chứa) của jsonb được index nào hỗ trợ?</details>
<details><summary>H2</summary><code>CREATE INDEX … USING gin (properties …)</code>. Có hai operator class cho jsonb; một cái chỉ hỗ trợ <code>@&gt;</code> và nhỏ hơn.</details>
<details><summary>H3</summary><code>CREATE INDEX ON events USING gin (properties jsonb_path_ops);</code></details>

## ex02 · BRIN
<details><summary>H1</summary>Index nào chỉ lưu min/max theo nhóm page?</details>
<details><summary>H2</summary><code>USING brin (cột)</code>; hợp với cột có thứ tự trùng thứ tự chèn.</details>
<details><summary>H3</summary><code>CREATE INDEX ON events USING brin (created_at);</code></details>

## ex03 · Chứa chuỗi
<details><summary>H1</summary>B-tree không giúp được <code>%…%</code>. Chia chuỗi thành các lát 3 ký tự thì sao?</details>
<details><summary>H2</summary>Extension <code>pg_trgm</code> cung cấp operator class cho GIN và GiST.</details>
<details><summary>H3</summary><code>CREATE INDEX ON users USING gin (email gin_trgm_ops);</code></details>

## ex04 · Full-text
<details><summary>H1</summary>Index phải nằm trên đúng biểu thức xuất hiện trong WHERE.</details>
<details><summary>H2</summary><code>USING gin (to_tsvector('simple', name))</code>; cấu hình text search phải là hằng, giống hệt truy vấn.</details>
<details><summary>H3</summary><code>CREATE INDEX ON products USING gin (to_tsvector('simple', name));</code></details>

## ex05 · GiST cho range
<details><summary>H1</summary>B-tree sắp theo thứ tự; "chồng lấn" không phải quan hệ thứ tự.</details>
<details><summary>H2</summary><code>USING gist (during)</code>.</details>
<details><summary>H3</summary><code>CREATE INDEX ON p05.booking USING gist (during);</code></details>

## ex06 · Quá nhiều index
<details><summary>H1</summary>Chạy <code>EXPLAIN</code> từng truy vấn và ghi lại tên index xuất hiện.</details>
<details><summary>H2</summary>Truy vấn 2 và 3 lấy nhiều dòng nên không dùng index; truy vấn 6 lấy giá trị hiếm.</details>
<details><summary>H3</summary>Bỏ <code>t_flag_idx</code> và <code>t_name_trgm</code>. Giữ <code>t_user_idx</code>, <code>t_ts_brin</code>, <code>t_payload_gin</code>, <code>t_status_idx</code>.</details>

## ex07 · Dung lượng và thời gian build
<details><summary>H1</summary>B-tree và GIN lưu mỗi dòng ít nhất một entry. BRIN lưu mỗi nhóm page một entry.</details>
<details><summary>H2</summary>N tăng 100× thì B-tree/GIN tăng ~100×; BRIN tăng theo số page (cũng tuyến tính, nhưng hệ số nhỏ hơn 2 000 lần).</details>
<details><summary>H3</summary>BRIN chỉ hiệu quả khi min/max của mỗi nhóm page là khoảng hẹp. Xáo trộn thứ tự làm mọi khoảng phủ gần như cả miền giá trị.</details>
