# R06 · Dữ liệu cây

Đọc khoảng 10 phút. Ví dụ chạy trên DB `lab` (schema `r06`: bản sao cây danh mục của `shop_*`, 42 nút, sâu 4 tầng) và `shop_s`. Cần recursive CTE (I02).

## Mục tiêu: sau buổi này bạn làm được
- Biểu diễn cây theo bốn cách: **adjacency list**, **ltree**, **closure table**, **nested set**, và viết truy vấn cây con / tổ tiên cho từng cách.
- Di chuyển một cây con và giữ biểu diễn nhất quán.
- Chặn chu trình trong adjacency list.
- So sánh bốn cách bằng số đo thật (đọc, ghi, dung lượng) và chọn cho từng tình huống.

---

## 1. Bốn cách biểu diễn
| | Lưu gì | Cây con của n | Tổ tiên của n | Chèn lá | Di chuyển cây con |
|---|---|---|---|---|---|
| **Adjacency list** | `parent_id` | recursive CTE | recursive CTE (đi lên) | 1 dòng | **1 dòng** |
| **ltree** | `path` (vd. `2.16.34`) + GiST | `path <@ 'n'` | `path @> 'n'` | 1 dòng | ghi lại path của mọi hậu duệ |
| **Closure table** | mọi cặp (tổ tiên, hậu duệ, depth) | 1 JOIN | 1 JOIN | thêm ~depth dòng | xóa + dựng lại cặp |
| **Nested set** | `lft`, `rgt` theo duyệt trước | `lft BETWEEN` | `lft < x AND rgt > y` | dịch chuyển nhiều dòng | dịch chuyển cả đoạn lớn của bảng |

Số liệu cụ thể (đo thật ở ex09): ở 1.1M nút, di chuyển cây con 11 111 nút mất 0.2 ms (adjacency), 244 ms (ltree), 624 ms (closure), 7.3 s (nested set).

## 2. Adjacency list + recursive CTE
```sql
WITH RECURSIVE sub AS (
  SELECT id, name, 1 AS depth FROM categories WHERE parent_id = 2          -- neo: con trực tiếp
  UNION ALL
  SELECT c.id, c.name, s.depth + 1 FROM categories c JOIN sub s ON c.parent_id = s.id
) SELECT * FROM sub;
```
- Đơn giản, ghi rẻ, FK đảm bảo cha tồn tại. Thiếu: **không tự chặn chu trình** (A cha của B, B cha của A) → recursive CTE chạy vô hạn. Chặn bằng trigger (ex08) hoặc mảng đường đi + `WHERE NOT id = ANY(path)` (I02).
- Cần index trên `parent_id` (FK không tự có index!). Không có thì mỗi bước đệ quy là một Seq Scan.
- Cây con 11 111 nút ở 1.1M nút mất 14.6 ms; đủ tốt cho phần lớn ứng dụng (ex09).

## 3. ltree
```sql
-- extension ltree (có sẵn trong lab/shop_*): nhãn nối bằng dấu chấm
UPDATE cat SET path = t.p FROM (WITH RECURSIVE …) t WHERE t.id = cat.id;
SELECT * FROM cat WHERE path <@ '2.16';      -- hậu duệ của 16 (cả chính nó)
SELECT * FROM cat WHERE path @> '2.16.34';   -- tổ tiên của 34 (cả chính nó)
SELECT nlevel(path), subpath(path, 1), path || 'x' FROM cat;
CREATE INDEX ON cat USING gist (path);
```
- Nhãn chỉ gồm chữ, số, `_` (và `-` từ Postgres 16), tối đa 1000 byte mỗi nhãn. Dùng `id` làm nhãn thì đổi tên nút không ảnh hưởng path.
- Di chuyển cây con = đổi tiền tố path của mọi hậu duệ (ex06); phải làm cùng transaction với việc đổi `parent_id` nếu bạn giữ cả hai cột.
- Phải **giữ đồng bộ** path với `parent_id` bằng trigger hoặc chỉ giữ path.

## 4. Closure table
`closure(ancestor, descendant, depth)` có cả cặp `(n, n, 0)`. Cây con của n: `WHERE ancestor = n`; tổ tiên: `WHERE descendant = n ORDER BY depth DESC`; đếm sản phẩm trong cây con của gốc là JOIN phẳng (ex05).
Đọc nhanh nhất, nhưng tốn chỗ O(N × độ sâu) và phải sửa bảng này ở mọi INSERT/di chuyển.

## 5. Nested set
Mỗi nút giữ `[lft, rgt]` theo duyệt trước; hậu duệ có khoảng nằm trong khoảng của tổ tiên. Số hậu duệ = `(rgt - lft - 1) / 2` tính thẳng (ex07). Chèn hoặc di chuyển một nút phải **dịch chuyển lft/rgt của mọi nút phía sau**: O(N) dòng ghi và khóa. Tìm tổ tiên (`lft < x AND rgt > y`) không dùng được index hiệu quả: 114 ms ở 1.1M nút (ex09).

## 6. Chọn cách nào
- Mặc định: **adjacency list + recursive CTE** (cây danh mục, org chart; thay đổi thường, đọc vừa phải).
- Đọc cây con/tổ tiên rất nhiều, di chuyển hiếm: **ltree** hoặc **closure**.
- Tránh nested set trừ khi cây gần như bất biến. Cây có hàng chục triệu nút hoặc cần đồ thị tổng quát (nhiều cha): xem D-tier, cân nhắc đồ thị chuyên dụng.

## Bẫy hay gặp
1. Quên cặp `(n, n, 0)` trong closure → "cây con của n" thiếu chính n.
2. Di chuyển cây con chỉ sửa nút gốc của nó, quên hậu duệ (ltree/closure/nested set).
3. Thiếu index `parent_id` cho adjacency list.
4. Không chặn chu trình → recursive CTE treo.
5. `replace()` trên text của path để đổi tiền tố: trúng nhãn trùng (`'2.16'` nằm trong `'12.162'`). Dùng `subpath`/`nlevel` hoặc so khớp theo nhãn.

## Postgres-specific
- `ltree` là extension contrib (`CREATE EXTENSION ltree`), có sẵn trong `lab` và template `shop_*` của workspace.
- Postgres không có `CONNECT BY` như Oracle; recursive CTE (chuẩn SQL) là công cụ chính. `SEARCH DEPTH FIRST BY … SET …` và `CYCLE … SET …` (Postgres 14+) giúp sắp xếp theo duyệt sâu và phát hiện chu trình ngay trong CTE.
