# F09 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Bảng khách hàng
<details><summary>H1</summary>Identity có hai kiểu: <code>ALWAYS</code> và <code>BY DEFAULT</code>. Kiểu nào cấm điền tay?</details>
<details><summary>H2</summary><code>id bigint GENERATED … AS IDENTITY PRIMARY KEY</code>; <code>email text NOT NULL UNIQUE</code>; <code>created_at … DEFAULT …</code></details>
<details><summary>H3</summary><code>GENERATED ALWAYS</code>; <code>created_at timestamptz NOT NULL DEFAULT now()</code>; <code>phone text</code> không có ràng buộc.</details>

## ex02 · Bảng sản phẩm
<details><summary>H1</summary>Định dạng chuỗi: <code>CHECK (sku ~ 'regex')</code>. Regex phải khớp <b>cả chuỗi</b>.</details>
<details><summary>H2</summary>Neo regex: <code>'^…$'</code>. Tập giá trị: <code>CHECK (status IN (…))</code>. Mọi cột có CHECK cũng cần <code>NOT NULL</code>.</details>
<details><summary>H3</summary><code>'^[A-Z]{2}-[0-9]{4}$'</code>; <code>stock int NOT NULL DEFAULT 0 CHECK (stock &gt;= 0)</code>; <code>status text NOT NULL DEFAULT 'draft' CHECK (…)</code>.</details>

## ex03 · Đơn hàng và khóa ngoại
<details><summary>H1</summary>Mỗi FK có một hành vi <code>ON DELETE</code>. Dòng hàng "thuộc về" đơn, còn đơn không "thuộc về" khách theo nghĩa đó.</details>
<details><summary>H2</summary>orders → customers: <code>RESTRICT</code> (hoặc mặc định). items → orders: <code>CASCADE</code>. items → products: mặc định. Rồi xem cột FK nào chưa là cột đầu của index nào.</details>
<details><summary>H3</summary>PK <code>(order_id, line_no)</code> đã phủ <code>order_id</code>. Cần thêm <code>CREATE INDEX ON f09.c_orders (customer_id)</code> và <code>CREATE INDEX ON f09.c_order_items (product_id)</code>.</details>

## ex04 · Dọn email trùng rồi khóa lại
<details><summary>H1</summary>Ba lệnh theo đúng thứ tự: DELETE → UPDATE → tạo ràng buộc. Ràng buộc phải áp lên email <b>đã chuẩn hóa</b>.</details>
<details><summary>H2</summary>DELETE self join như F08 ex06. Ràng buộc: <code>CREATE UNIQUE INDEX … ON f09.legacy_users (&lt;biểu thức&gt;)</code>.</details>
<details><summary>H3</summary>Điều kiện xóa: <code>(k.created_at, k.id) &lt; (s.created_at, s.id)</code>. Index: <code>(lower(trim(email)))</code>, nhớ hai lớp ngoặc.</details>

## ex05 · Cột tính sẵn
<details><summary>H1</summary><code>GENERATED ALWAYS AS (…) STORED</code>.</details>
<details><summary>H2</summary>Biểu thức: <code>round(quantity * unit_price * (1 - discount_pct / 100), 2)</code>. Đừng quên CHECK cho discount.</details>
<details><summary>H3</summary><code>discount_pct numeric(5,2) NOT NULL DEFAULT 0 CHECK (discount_pct BETWEEN 0 AND 100)</code>.</details>

## ex06 · Khuyến mãi
<details><summary>H1</summary>"Đúng một trong hai" là một CHECK mức bảng. Hãy nhớ: CHECK cho NULL đi qua.</details>
<details><summary>H2</summary>Có hàm <code>num_nonnulls(…)</code>. Khoảng giá trị dùng CHECK trên từng cột (NULL vẫn qua, đúng ý đề).</details>
<details><summary>H3</summary><code>CHECK (num_nonnulls(percent, amount) = 1)</code>, <code>CHECK (ends_at &gt; starts_at)</code> (NULL → qua).</details>

## ex07 · Mỗi khách một địa chỉ mặc định
<details><summary>H1</summary>Ràng buộc UNIQUE chỉ áp lên <b>một phần</b> các dòng.</details>
<details><summary>H2</summary><code>CREATE UNIQUE INDEX … ON f09.addresses (…) WHERE …;</code></details>
<details><summary>H3</summary><code>(user_id) WHERE is_default</code>.</details>

## ex08 · Sơ đồ nhân sự
<details><summary>H1</summary>FK có thể trỏ về chính bảng của nó. UNIQUE coi NULL thế nào?</details>
<details><summary>H2</summary><code>manager_id int REFERENCES f09.employees (id) ON DELETE …</code> + <code>CHECK (…)</code>.</details>
<details><summary>H3</summary><code>ON DELETE SET NULL</code>, <code>CHECK (manager_id &lt;&gt; id)</code>, <code>work_email text UNIQUE</code> (UNIQUE thường, không thêm NULLS NOT DISTINCT).</details>

## ex09 · Đặt phòng họp
<details><summary>H1</summary>Tên: unique index trên biểu thức. Chồng giờ: exclusion constraint (README mục 7).</details>
<details><summary>H2</summary><code>EXCLUDE USING gist (room_id WITH =, tstzrange(starts_at, ends_at) WITH &amp;&amp;) WHERE (…)</code></details>
<details><summary>H3</summary><code>WHERE (status = 'confirmed')</code>; giữ cận mặc định <code>[)</code>; thêm <code>CHECK (ends_at &gt; starts_at)</code>; <code>CREATE UNIQUE INDEX ON f09.rooms (lower(name))</code>.</details>

## ex10 · Đổi kiểu cột giá
<details><summary>H1</summary><code>ALTER TABLE … ALTER COLUMN … TYPE … USING &lt;biểu thức chuyển đổi&gt;</code>.</details>
<details><summary>H2</summary>Bỏ mọi ký tự không phải số bằng <code>regexp_replace(…, '[^0-9]', '', 'g')</code>, rồi ép sang numeric.</details>
<details><summary>H3</summary><code>USING regexp_replace(price, '[^0-9]', '', 'g')::numeric</code>, sau đó <code>ALTER TABLE f09.imports ADD CHECK (price &gt;= 0)</code>.</details>
