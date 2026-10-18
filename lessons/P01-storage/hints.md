# P01 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Một bảng chiếm bao nhiêu?
<details><summary>H1</summary><code>pg_relation_size('orders')</code> trả về byte của heap.</details>
<details><summary>H2</summary>Chia cho <code>current_setting('block_size')::int</code> để ra page; <code>count(*)</code> cho số dòng.</details>
<details><summary>H3</summary><code>round(n_rows::numeric / n_pages, 1)</code> và <code>round(pg_relation_size('orders')::numeric / n_rows)</code>.</details>

## ex02 · Dòng nằm ở đâu?
<details><summary>H1</summary><code>ctid</code> là kiểu <code>tid</code>, in ra dạng <code>(page,slot)</code>.</details>
<details><summary>H2</summary>Cast <code>ctid::text::point</code> rồi lấy phần tử <code>[0]</code> và <code>[1]</code>.</details>
<details><summary>H3</summary><code>(ctid::text::point)[0]::int AS page_no</code>, <code>[1]</code> cho slot. <code>WHERE id &lt;= 5 ORDER BY id</code>.</details>

## ex03 · Bao nhiêu byte thật sự được lưu?
<details><summary>H1</summary><code>octet_length</code> cho độ dài gốc, một hàm khác cho kích thước đang lưu (có tính nén).</details>
<details><summary>H2</summary><code>pg_column_size(body)</code> và <code>pg_column_compression(body)</code> (NULL nếu không nén).</details>
<details><summary>H3</summary><code>count(pg_column_compression(body))</code> đếm các dòng đã nén (count bỏ qua NULL).</details>

## ex04 · Heap và TOAST
<details><summary>H1</summary>Bảng TOAST là một relation riêng; tìm nó ở <code>pg_class.reltoastrelid</code>.</details>
<details><summary>H2</summary><code>pg_relation_size('p01.docs')</code> cho heap, <code>pg_relation_size(reltoastrelid)</code> cho TOAST (join <code>pg_class</code> theo <code>'p01.docs'::regclass</code>).</details>
<details><summary>H3</summary>Đừng dùng <code>pg_total_relation_size</code> cho phần heap: nó đã gồm TOAST và index.</details>

## ex05 · Đếm mà không kéo TOAST
<details><summary>H1</summary>Hàm nào cần giá trị đầy đủ của <code>body</code> thì buộc phải đọc chunk TOAST. Có hàm chỉ đọc độ dài từ con trỏ.</details>
<details><summary>H2</summary><code>length()</code> đếm ký tự (phải detoast); <code>octet_length()</code> đếm byte.</details>
<details><summary>H3</summary><code>SELECT count(*) AS n FROM p01.docs WHERE octet_length(body) &gt; 50000</code>.</details>

## ex06 · Xếp lại cột
<details><summary>H1</summary>Alignment: <code>bigint</code> cần địa chỉ chia hết cho 8, <code>boolean</code> thì không. Byte đệm sinh ra khi hai loại xen nhau.</details>
<details><summary>H2</summary>Đặt các cột cùng alignment cạnh nhau, rộng nhất trước.</details>
<details><summary>H3</summary>Thứ tự <code>b, d, f, a, c, e</code>.</details>

## ex07 · "Bộ đếm cứ phình ra"
<details><summary>H1</summary>Để HOT cần chỗ trống trong cùng page. Page hiện tại đầy 100%.</details>
<details><summary>H2</summary>Hạ <code>fillfactor</code> của bảng, rồi làm cho các page cũ được ghi lại theo fillfactor mới (rewrite).</details>
<details><summary>H3</summary><code>ALTER TABLE … SET (fillfactor = 70)</code> rồi <code>CLUSTER … USING counters_pkey</code>.</details>

## ex08 · Dự toán dung lượng
<details><summary>H1</summary>Tương tự ex01, cho 4 bảng.</details>
<details><summary>H2</summary><code>UNION ALL</code> bốn SELECT, mỗi cái gồm tên bảng, <code>count(*)</code>, <code>pg_relation_size(…)</code>.</details>
<details><summary>H3</summary>Dùng <code>pg_relation_size('events'::regclass)</code> trong từng nhánh, chia cho <code>block_size</code> và cho số dòng.</details>

## ex09 · Dự đoán dung lượng
<details><summary>H1</summary>Dung lượng heap tỉ lệ thuận với số dòng nếu bytes/dòng không đổi.</details>
<details><summary>H2</summary>Dự đoán = bytes_per_row × N. Nhớ <code>events</code> có N × 3.24 dòng, không phải N.</details>
<details><summary>H3</summary>So sánh với số đo thật và tìm nguồn sai lệch: độ dài cột thay đổi theo seed, page header, fillfactor 100.</details>
