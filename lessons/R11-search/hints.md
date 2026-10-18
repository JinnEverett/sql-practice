# R11 · Gợi ý

Mở từng cấp khi bí, mỗi lần mở tính 1 hint. Đáp án ở `solutions/exNN.sql`.

## ex01 · Full-text căn bản
<details><summary>H1</summary>Toán tử <code>@@</code> so khớp <code>tsvector</code> với <code>tsquery</code>. Cấu hình cho tiếng Việt: <code>'simple'</code>.</details>
<details><summary>H2</summary><code>to_tsvector('simple', name) @@ plainto_tsquery('simple', 'tai nghe')</code>.</details>
<details><summary>H3</summary><code>plainto_tsquery</code> nối các từ bằng AND, nên tên phải chứa cả "tai" và "nghe". <code>LIKE</code> phân biệt hoa/thường nên sẽ bỏ sót "Tai nghe".</details>

## ex02 · Gom từ khóa
<details><summary>H1</summary>Cần một biểu thức chuẩn hóa dùng cho <code>GROUP BY</code>: bỏ dấu và chữ thường.</details>
<details><summary>H2</summary><code>lower(unaccent(properties-&gt;&gt;'query'))</code>; số cách viết: <code>count(DISTINCT properties-&gt;&gt;'query')</code>.</details>
<details><summary>H3</summary>Lọc <code>event_type = 'search'</code>; <code>GROUP BY 1</code>; <code>ORDER BY n_searches DESC, normalized_query</code>.</details>

## ex03 · Xếp hạng có trọng số
<details><summary>H1</summary>Gắn nhãn trọng số cho từng phần tài liệu trước khi nối chúng lại.</details>
<details><summary>H2</summary><code>setweight(to_tsvector('simple', unaccent(title)), 'A') || setweight(to_tsvector('simple', unaccent(body)), 'B')</code>; câu hỏi <code>plainto_tsquery('simple', unaccent('chỉ mục'))</code>.</details>
<details><summary>H3</summary><code>ts_rank_cd(vec, query)</code>, lọc bằng <code>vec @@ query</code>, <code>round(…::numeric, 4)</code>; <code>ORDER BY rank DESC, id</code>.</details>

## ex04 · Tìm mờ
<details><summary>H1</summary>Extension <code>pg_trgm</code> có hàm <code>similarity</code> và toán tử <code>%</code>.</details>
<details><summary>H2</summary>Trigram phân biệt dấu: bỏ dấu phía tên sản phẩm bằng <code>lower(unaccent(name))</code>.</details>
<details><summary>H3</summary><code>WHERE lower(unaccent(name)) % 'op lung samsug' ORDER BY sim DESC, id LIMIT 5</code>.</details>

## ex05 · Tìm chuỗi con có index
<details><summary>H1</summary>B-tree không giúp được mẫu bắt đầu bằng <code>%</code>. Cần index cắt chuỗi thành các mảnh nhỏ.</details>
<details><summary>H2</summary>Index GIN với operator class của <code>pg_trgm</code>.</details>
<details><summary>H3</summary><code>CREATE INDEX … ON users USING gin (full_name gin_trgm_ops);</code> rồi <code>-- query</code> và câu SELECT.</details>

## ex06 · Bỏ dấu có index
<details><summary>H1</summary>Lỗi 42P17 nghĩa là biểu thức không IMMUTABLE. <code>unaccent(text)</code> chỉ STABLE.</details>
<details><summary>H2</summary>Hàm bọc: <code>LANGUAGE sql IMMUTABLE</code>, thân <code>SELECT public.unaccent('public.unaccent', $1)</code> (từ điển cố định).</details>
<details><summary>H3</summary>Cột: <code>ADD COLUMN search_vec tsvector GENERATED ALWAYS AS (to_tsvector('simple', public.f_unaccent(name))) STORED</code>; index <code>USING gin (search_vec)</code>; truy vấn dùng chính <code>public.f_unaccent</code> cho câu hỏi.</details>

## ex07 · Ô tìm kiếm kiểu Google
<details><summary>H1</summary>Hàm tạo tsquery nào hiểu dấu nháy kép và dấu trừ, và không bao giờ báo lỗi?</details>
<details><summary>H2</summary><code>websearch_to_tsquery('simple', …)</code>. Bỏ dấu cả đầu vào lẫn tên sản phẩm.</details>
<details><summary>H3</summary><code>to_tsvector('simple', unaccent(name)) @@ websearch_to_tsquery('simple', unaccent('"tai nghe" -sony'))</code>.</details>

## ex08 · Câu hỏi quy mô
<details><summary>H1</summary>Số dòng kết quả quyết định index giúp nhiều hay ít.</details>
<details><summary>H2</summary>Q3 trả về 23 284 dòng rải khắp bảng 353 MB. Bitmap Heap Scan phải đọc bao nhiêu page?</details>
<details><summary>H3</summary>Ở <code>s</code> bảng nhỏ (15 buffer) nên planner chọn Seq Scan dù có index.</details>
