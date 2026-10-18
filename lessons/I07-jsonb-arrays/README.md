# I07 · JSONB & arrays

Đọc khoảng 10 phút. Ví dụ chạy trên `shop_s`.

## Mục tiêu: sau buổi này bạn làm được
- Đọc dữ liệu jsonb: `->`, `->>`, `#>`, `#>>`, ép kiểu đúng.
- Lọc bằng các toán tử chỉ có ở jsonb: `?` (có key), `@>` (chứa), jsonpath `@?` / `@@`.
- Dựng JSON từ bảng (`jsonb_build_object`, `jsonb_agg`) và "bung" JSON thành bảng (`jsonb_object_keys`, `jsonb_each`, `jsonb_array_elements`).
- Sửa jsonb: `||`, `-`, `jsonb_set`, `jsonb_strip_nulls`.
- Dùng mảng: `ARRAY[…]`, `array_agg`, `unnest`, `@>`, `&&`, `= ANY`.
- Biết khi nào **không** nên dùng jsonb.

---

## 1. Đọc
```sql
SELECT attributes,                              -- {"color": "đen", "weight_g": 1900, "warranty_months": 24}
       attributes -> 'color'           AS j,    -- "đen"   (kiểu jsonb, còn ngoặc kép)
       attributes ->> 'color'          AS t,    -- đen     (kiểu text)
       (attributes ->> 'weight_g')::int AS w,   -- 1900    (text → int)
       attributes ->> 'size'           AS s     -- NULL    (key không có → NULL, không lỗi)
FROM products WHERE id = 1;
```
- `->` trả về jsonb, `->>` trả về text. Muốn số hay ngày thì lấy `->>` rồi ép kiểu.
- Đường dẫn lồng nhau: `doc #> '{a,b}'` (jsonb), `doc #>> '{a,b}'` (text). Phần tử mảng: `doc -> 'items' -> 0`.
- ⚠️ So sánh `->>` là so **chuỗi**: `attributes->>'weight_g' > '2000'` thì `'950' > '2000'` là **true**. Luôn ép kiểu trước khi so số.

## 2. Lọc
| Toán tử | Ý nghĩa | Ví dụ |
|---|---|---|
| `?` | có key (ở mức đầu) | `properties ? 'device'` |
| `?|` / `?&` | có một trong / có tất cả các key | `attributes ?& array['color','size']` |
| `@>` | **chứa** cặp key-value | `properties @> '{"utm_source": "tiktok"}'` |
| `@?` | jsonpath có trả kết quả | `attributes @? '$ ? (@.weight_g > 2000)'` |
| `@@` | jsonpath dạng vị từ trả true | `attributes @@ '$.weight_g > 2000'` |

- `@>` và jsonpath dùng được **index GIN**. `->>` thì chỉ dùng được index B-tree trên **đúng biểu thức** đó (ex10).
- `'{"device": null}' ? 'device'` là **true**: key có tồn tại, chỉ là giá trị null. Còn `->> 'device' IS NULL` gộp cả hai trường hợp "thiếu key" và "giá trị null".

## 3. Dựng JSON và bung JSON
```sql
-- dựng: đơn kèm danh sách dòng hàng
SELECT jsonb_build_object('order_id', o.id,
         'items', (SELECT jsonb_agg(jsonb_build_object('product_id', product_id, 'qty', quantity) ORDER BY line_no)
                   FROM order_items WHERE order_id = o.id))
FROM orders o WHERE o.id = 3;

-- bung: mỗi key một dòng / mỗi cặp key-value một dòng
SELECT k, count(*) FROM products, jsonb_object_keys(attributes) k GROUP BY k;
SELECT key, value FROM products, jsonb_each(attributes) WHERE id = 1;
SELECT x FROM jsonb_array_elements('[1, 2, 3]'::jsonb) x;
```
- jsonb lưu key theo thứ tự **nội bộ** (key ngắn trước, cùng độ dài thì theo chữ cái), không theo thứ tự bạn viết. Hai object có cùng nội dung luôn in ra giống nhau.
- `jsonb_agg(… ORDER BY …)`: cần ORDER BY để mảng có thứ tự xác định.

## 4. Sửa
```sql
SELECT '{"a": 1, "b": null}'::jsonb || '{"c": 3}'       AS them,       -- {"a": 1, "b": null, "c": 3}
       '{"a": 1, "b": null}'::jsonb - 'a'               AS xoa,        -- {"b": null}
       jsonb_set('{"a": {"x": 1}}', '{a,x}', '2')       AS dat,        -- {"a": {"x": 2}}
       jsonb_strip_nulls('{"a": 1, "b": null}')         AS bo_null;    -- {"a": 1}
```
- jsonb không sửa "tại chỗ" được: `UPDATE … SET attributes = <object mới>` ghi lại **cả object** (và cả dòng, theo MVCC ở P07). Document lớn và hay sửa thì tốn kém.
- `||` ghép nông: vế phải ghi đè key trùng ở mức đầu, không trộn đệ quy object lồng nhau.

## 5. Mảng
```sql
SELECT ARRAY[1, 4] <@ ARRAY[1, 2, 4]   AS bi_chua,       -- true
       ARRAY[1, 4] && ARRAY[4, 9]      AS giao_nhau,     -- true
       4 = ANY (ARRAY[1, 4])           AS co_phan_tu,    -- true
       cardinality(ARRAY[1, 2, 3])     AS so_phan_tu,    -- 3
       (ARRAY['a', 'b', 'c'])[2]       AS phan_tu_2;     -- b  (chỉ số bắt đầu từ 1!)
SELECT order_id, array_agg(product_id ORDER BY product_id) FROM order_items WHERE order_id <= 2 GROUP BY order_id;
SELECT unnest(ARRAY['x', 'y']);
```

## 6. Khi nào dùng jsonb?
- **Nên dùng:** thuộc tính thay đổi theo loại sản phẩm, payload event, cấu hình, dữ liệu từ API bên ngoài. Tức là dữ liệu **ít khi lọc/join**, schema thay đổi thường xuyên.
- **Không nên:** cột hay lọc, hay join, cần ràng buộc (`NOT NULL`, FK, `CHECK`), cần thống kê chính xác cho planner. Key nào bạn lọc trong mọi query thì nên tách thành **cột thật**.
- Planner gần như không có thống kê bên trong jsonb, nên hay ước lượng sai số dòng (P04).

## Bẫy hay gặp
1. So sánh `->>` như số mà không ép kiểu.
2. `->` (jsonb) làm nhãn hoặc nối chuỗi → dính ngoặc kép.
3. `count(DISTINCT user_id)` để đếm người khi có khách vãng lai (NULL).
4. Chỉ số mảng bắt đầu từ **1**.
5. Tạo index nhưng viết điều kiện kiểu khác (GIN cho `@>` nhưng query dùng `->>`).

## Postgres-specific
- `jsonb` (nhị phân, có index) khác `json` (lưu nguyên văn, giữ thứ tự key và khoảng trắng). Gần như luôn dùng `jsonb`.
- MySQL có JSON với `->`/`->>` nhưng không có GIN, `@>` hay jsonpath đầy đủ.
