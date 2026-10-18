# R11 · Search: full-text, fuzzy, tiếng Việt

Đọc khoảng 10 phút. Ví dụ chạy trên `shop_s` (bảng `products`, `users`, `events`) và DB `lab` (schema `r11`, bài báo mẫu). Extension `unaccent`, `pg_trgm` có sẵn trong `shop_*` và `lab`. Cần index GIN (P05); nếu chưa học, đọc phần 4 trước.

## Mục tiêu: sau buổi này bạn làm được
- Dùng `tsvector`/`tsquery`, `@@`, xếp hạng bằng `ts_rank_cd` với trọng số tiêu đề/nội dung.
- Xử lý tiếng Việt **có dấu và không dấu** bằng `unaccent` đúng cách (hàm IMMUTABLE bọc ngoài, cột sinh, index GIN).
- Tìm mờ (chịu gõ sai) bằng `pg_trgm`: `similarity`, `%`, `ILIKE '%…%'` có index.
- Nhận cú pháp ô tìm kiếm của người dùng bằng `websearch_to_tsquery`.
- Đo khi nào index tìm kiếm giúp nhiều, khi nào ít.

---

## 1. Full-text search căn bản
```sql
SELECT to_tsvector('simple', 'Tai nghe Sony 0252');   -- '0252':4 'nghe':2 'sony':3 'tai':1  (chữ thường + vị trí)
SELECT plainto_tsquery('simple', 'tai nghe');          -- 'tai' & 'nghe'
SELECT to_tsvector('simple', name) @@ plainto_tsquery('simple', 'tai nghe') FROM products;
```
- Postgres **không có cấu hình tiếng Việt** (không stemmer, không stopword). Dùng `simple`: tách từ theo khoảng trắng/dấu câu và đưa về chữ thường; mỗi âm tiết là một token (`tai`, `nghe`). Cụm từ như "tai nghe" khớp bằng AND hoặc toán tử cụm `<->` (hai token liền nhau), không phải một "từ ghép".
- Cấu hình `english` sẽ stem và bỏ stopword theo tiếng Anh: sai với tiếng Việt (ex01 dùng `simple`).
- Các hàm tạo tsquery: `plainto_tsquery` (AND các từ, bỏ qua toán tử), `phraseto_tsquery` (cụm liền nhau), `to_tsquery` (cú pháp đầy đủ `a & b | !c`, **ném lỗi** với đầu vào lạ), `websearch_to_tsquery` (cú pháp kiểu Google, không bao giờ lỗi) (ex07).

## 2. Tiếng Việt có dấu và không dấu
Người dùng gõ cả "áo thun" lẫn "ao thun". Cách thông dụng: **bỏ dấu cả hai phía** (dữ liệu và câu hỏi) rồi tìm trên dạng không dấu.
```sql
SELECT unaccent('Đường Đỗ ắ');           -- Duong Do a   (xử lý cả Đ/đ)
```
- Nhưng `unaccent(text)` chỉ **STABLE**, nên không dùng được trong cột `GENERATED` hay index biểu thức. Bọc bằng hàm IMMUTABLE gọi bản hai tham số với tên từ điển cố định (ex06):
```sql
CREATE FUNCTION f_unaccent(text) RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT
AS $$ SELECT public.unaccent('public.unaccent', $1) $$;
ALTER TABLE products ADD COLUMN search_vec tsvector GENERATED ALWAYS AS (to_tsvector('simple', f_unaccent(name))) STORED;
CREATE INDEX ON products USING gin (search_vec);
-- truy vấn:  WHERE search_vec @@ plainto_tsquery('simple', f_unaccent('áo thun'))
```
- Khai báo IMMUTABLE là một lời hứa: nếu bạn đổi nội dung từ điển `unaccent` sau này, dữ liệu đã lập chỉ mục có thể lệch; khi đó phải `REINDEX`/tính lại cột.
- Hiển thị cho người dùng thì giữ nguyên chữ có dấu; chỉ dùng dạng không dấu để **so khớp**.

## 3. Xếp hạng và trọng số
```sql
setweight(to_tsvector('simple', unaccent(title)), 'A') || setweight(to_tsvector('simple', unaccent(body)), 'B')
ts_rank_cd(vec, query)            -- mật độ phủ; trọng số mặc định A=1.0, B=0.4, C=0.2, D=0.1
```
Từ khớp ở tiêu đề (A) đẩy rank cao hơn ở nội dung (B) (ex03). `ts_rank` chỉ đếm tần suất; `ts_rank_cd` có tính khoảng cách giữa các từ. Tham số thứ ba chuẩn hóa theo độ dài tài liệu. Xếp hạng phải đọc tsvector của MỌI tài liệu khớp: tập kết quả lớn thì chậm; lọc/giới hạn trước khi xếp hạng. Luôn thêm `id` làm tie-breaker.
`ts_headline` tạo đoạn trích có tô sáng, chạy trên văn bản gốc và đắt, chỉ gọi cho trang kết quả đã `LIMIT`.

## 4. Tìm mờ với `pg_trgm`
```sql
SELECT similarity('op lung samsug', 'op lung samsung');     -- 0.81 (tỉ lệ bộ ba ký tự chung)
SELECT * FROM products WHERE lower(unaccent(name)) % 'op lung samsug';   -- similarity > 0.3, dùng được index
CREATE INDEX ON users USING gin (full_name gin_trgm_ops);    -- phục vụ cả  ILIKE '%…%'  và  %
```
- Trigram không phân biệt hoa/thường nhưng **phân biệt dấu** (`ốp` ≠ `op`): bỏ dấu cả hai phía (ex04).
- GIN trigram phục vụ `LIKE/ILIKE '%giữa%'` với mẫu dài ≥ 3 ký tự (ex05). B-tree chỉ phục vụ `'đầu%'` (và cần `text_pattern_ops` hoặc collation "C").
- Ngưỡng: `SET pg_trgm.similarity_threshold = 0.4`. Với tập lớn, sắp xếp theo khoảng cách `<->` với GiST index (`ORDER BY name <-> 'x' LIMIT 10`) tìm top-k gần nhất rất nhanh.

## 5. Chọn công cụ
| Nhu cầu | Công cụ |
|---|---|
| tìm theo *từ* (kể cả bỏ dấu), có xếp hạng | FTS (`tsvector`, GIN) |
| gõ sai, tìm chuỗi con, gợi ý tên | `pg_trgm` (GIN/GiST) |
| tìm theo nghĩa | extension vector (`pgvector`), ngoài phạm vi |
| hàng chục triệu văn bản, facet, tìm kiếm là sản phẩm lõi | công cụ chuyên dụng (OpenSearch/Elasticsearch, Meilisearch, Typesense) |

## Bẫy hay gặp
1. `LIKE '%tai nghe%'` phân biệt hoa/thường và không dùng được B-tree.
2. Dùng `unaccent()` trực tiếp trong cột sinh/index (lỗi 42P17) hoặc quên bỏ dấu câu hỏi bằng cùng hàm.
3. `to_tsquery` với đầu vào thô của người dùng (lỗi cú pháp).
4. Index trigram cho mẫu quá ngắn (< 3 ký tự) vô dụng; index kỳ vọng ở dữ liệu bé nhưng planner chọn Seq Scan.
5. Quên tie-breaker; xếp hạng trên tập kết quả khổng lồ.
6. So khớp văn bản có dấu với câu hỏi không dấu (hoặc ngược lại) mà không chuẩn hóa hai phía.

## Postgres-specific
- `GENERATED ALWAYS AS (…) STORED` từ Postgres 12; `websearch_to_tsquery` từ 11; mặc định `default_text_search_config` phụ thuộc locale (nên luôn ghi tường minh `'simple'`).
- `gin_trgm_ops` cần extension `pg_trgm`; `unaccent` cần extension `unaccent`. Cả hai có sẵn trong template `shop_template` và DB `lab` của workspace.
