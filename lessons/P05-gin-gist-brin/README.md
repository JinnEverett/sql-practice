# P05 · Index đặc biệt: GIN, GiST, BRIN (và khi nào KHÔNG index)

Đọc khoảng 10 phút. Số đo trên `shop_m` (1M đơn, 3.24M events, 100k users, 20k products) và `lab.p05`, Postgres 18.6. Đo `BUFFERS` (hit + read); thời gian build chỉ để tham khảo (máy bạn sẽ khác).

## Mục tiêu: sau buổi này bạn làm được
- Chọn đúng loại index theo **toán tử trong WHERE**, không theo kiểu cột: B-tree (`= < > BETWEEN`), GIN (chứa/có phần tử/từ), GiST (gần/chồng lấn), BRIN (dữ liệu tương quan vật lý).
- Dùng GIN cho jsonb (`@>`), trigram (`LIKE '%…%'`), full-text search, array.
- Dùng GiST cho range (`&&`) và biết giới hạn; dùng BRIN cho bảng append-only rất lớn.
- Nhận ra index vô dụng: nhiều giá trị lặp, luôn lấy phần lớn bảng, không có truy vấn nào dùng.

---

## 1. Chọn theo toán tử
| tình huống | toán tử | index |
|---|---|---|
| `col = x`, `<`, `BETWEEN`, `ORDER BY`, `LIKE 'abc%'` (với `text_pattern_ops`) | so sánh, thứ tự | **B-tree** (P02) |
| jsonb chứa: `properties @> '{"product_id": 12345}'` | `@>`, `?`, `@?` | **GIN** |
| `LIKE '%abc%'`, `ILIKE`, `~` | trigram | **GIN/GiST** + `pg_trgm` |
| tìm theo từ: `to_tsvector(…) @@ to_tsquery(…)` | full-text | **GIN** (hoặc GiST) |
| array: `tags @> ARRAY['x']`, `&&` | chứa/chồng | **GIN** |
| range/geometry: `during && tstzrange(…)`, `<->` gần nhất | chồng lấn, khoảng cách | **GiST** |
| `created_at` của bảng append-only hàng trăm triệu dòng | `BETWEEN` trên cột tương quan với vị trí vật lý | **BRIN** |

Nguyên tắc: B-tree tồn tại cho **mọi** kiểu có thứ tự, và vì thế bẫy nhất là nó vẫn tạo được mà chẳng giúp gì cho toán tử khác (ex01, ex05).

## 2. GIN (Generalized Inverted Index)
Đảo ngược: từ mỗi "khóa con" (key của jsonb, token, phần tử mảng, trigram) trỏ tới danh sách dòng chứa nó. Tra cứu nhanh với toán tử "chứa"; ghi thì đắt (một dòng thêm nhiều entry; Postgres gom vào pending list `fastupdate` rồi trộn sau).
- jsonb có hai operator class: `jsonb_ops` (mặc định: hỗ trợ `@>`, `?`, `?|`, `?&`, `@?`, `@@`) và `jsonb_path_ops` (chỉ `@>`, `@?`, `@@`; nhỏ và nhanh hơn). Trên `events.properties`: `jsonb_path_ops` **13.9 MB** (build 0.9–1.0 s), `jsonb_ops` **19.6 MB** (build 2.1–2.3 s); `properties @> '{"product_id": 12345}'` (40 dòng): **44 buffers** thay vì quét 45 243 page.
- B-tree trên biểu thức `(properties->>'product_id')::int` (21 MB) cũng cho 43 buffers, nhưng **chỉ** với đúng truy vấn `… = 12345` và không phục vụ `@>`. Biết trước một khóa cố định thì B-tree biểu thức đủ; khóa tùy ý thì GIN.
- **GIN không cứu được truy vấn lấy nhiều:** `properties @> '{"utm_source": "email"}'` (49 863 dòng, 1.5%) dùng Bitmap Index Scan nhưng phải đọc **30 535 / 45 243 page heap** (dòng rải khắp bảng). Index tìm nhanh không có nghĩa là đọc heap ít.
- Trigram (`pg_trgm`): `email ILIKE '%hung.pham88%'` ở 100k users: GIN `gin_trgm_ops` **45 buffers**, GiST `gist_trgm_ops` **417 buffers**, không index **1 526**. GIN nhanh hơn khi đọc, GiST nhẹ hơn khi ghi. Chuỗi tìm cần ≥ 3 ký tự mới có trigram.
- Full-text: index **trên đúng biểu thức** `to_tsvector('simple', name)` và truy vấn phải dùng cùng cấu hình `'simple'` (ex04): 10 buffers thay vì 398.

## 3. GiST
Cây cân bằng tổng quát cho dữ liệu không có thứ tự toàn phần: range, hình học, trigram, `ltree`. Hỗ trợ `&&` (chồng), `@>`, `<@`, và `<->` (K láng giềng gần nhất). `lab.p05.booking` (300 000 khoảng 1 giờ): `during && tstzrange(…)` đọc **4 buffers** với GiST, so với Seq Scan 2 206 page. GiST cũng là cách duy nhất ép **exclusion constraint** (không cho hai đặt phòng chồng giờ, cần `btree_gist` để thêm cột `room WITH =`).
Bẫy: tạo B-tree trên cột range vẫn được (range có thứ tự) nhưng planner không dùng nó cho `&&`.

## 4. BRIN (Block Range Index)
Chỉ lưu min/max cho mỗi nhóm 128 page. Cực nhỏ và build nhanh, nhưng chỉ hiệu quả khi **giá trị cột tương quan với vị trí vật lý** (như `created_at` của bảng chỉ append).
`events.created_at` (3.24M dòng): B-tree **71 072 kB** (build 1.1–1.2 s); BRIN **32 kB** (build 0.17–0.22 s), nhỏ hơn 2 200×. Truy vấn một ngày (18 166 dòng): BRIN đọc **390 buffers** (384 block lossy, loại 9 702 dòng khi recheck), Seq Scan 45 243. BRIN trên cột không tương quan (`user_id`) không lọc được gì nên planner bỏ qua.

## 5. Khi nào KHÔNG nên index
- Điều kiện lấy phần lớn bảng (`status = 'delivered'`: 90% dòng): planner chọn Seq Scan, index chỉ tốn chỗ.
- Cột ít giá trị, phân phối đều (`flag boolean` 50/50).
- Bảng nhỏ (vài trăm page): Seq Scan rẻ hơn.
- Index không truy vấn nào dùng. Mỗi index thêm vào chi phí của mọi `INSERT/UPDATE/DELETE` (đo ở P10b). Dùng `pg_stat_user_indexes.idx_scan = 0` (theo dõi đủ lâu) để tìm.
- Cột có skew thì index vẫn hữu ích cho **giá trị hiếm** (`status = 'refunded'` 1%) nhưng vô dụng cho giá trị phổ biến: cân nhắc partial index (P02).

## Bẫy hay gặp
1. B-tree cho `@>`, `&&`, `LIKE '%x%'`: tạo được nhưng planner không dùng.
2. GIN trên jsonb với khóa/giá trị xuất hiện ở hàng chục % dòng.
3. `to_tsvector(col)` (không ghi cấu hình) trong index nhưng truy vấn ghi cấu hình khác, hoặc ngược lại: không khớp biểu thức.
4. BRIN trên dữ liệu bị `UPDATE`/xáo trộn làm mất tương quan.
5. Quên `CREATE EXTENSION pg_trgm` / `btree_gist`.
6. Chỉ nhìn tốc độ đọc mà quên tốc độ ghi và dung lượng của GIN.

## Đo bằng gì
- `EXPLAIN (ANALYZE, BUFFERS)` và loại node: `Bitmap Index Scan on <tên index>`; `pg_relation_size`; `pg_am` + `pg_class.relam` để biết access method của index.
- Giới hạn của phép đo: thời gian build/ghi thay đổi giữa máy; số buffers và kích thước thì ổn định.
