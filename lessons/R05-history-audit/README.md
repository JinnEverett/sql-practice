# R05 · Lịch sử dữ liệu: soft delete, audit, temporal, SCD2

Đọc khoảng 10 phút. Ví dụ chạy trên DB `lab` (schema `r05`, tạo bởi `setup.sql`) và `shop_s`.

## Mục tiêu: sau buổi này bạn làm được
- Cài soft delete đúng: view lọc, unique partial index, và biết các "tác dụng phụ" (FK, thống kê, privacy).
- Viết audit trigger ghi `old/new`, bỏ qua UPDATE không đổi gì, lưu phần thay đổi bằng jsonb.
- Dựng lại trạng thái của dữ liệu tại một thời điểm trong quá khứ từ nhật ký.
- Mô hình hóa lịch sử giá bằng SCD type 2 với khoảng thời gian nửa mở, và ép "không chồng nhau" bằng exclusion constraint.
- Đo chi phí ghi của audit.

---

## 1. Bốn cách giữ lịch sử
| Cách | Lưu gì | Hỏi được gì | Chi phí |
|---|---|---|---|
| Soft delete (`deleted_at`) | cờ trên chính dòng | "đã xóa chưa?" | rẻ; dữ liệu "đã xóa" vẫn nằm trong bảng, index, backup |
| Audit log (trigger) | mỗi thay đổi một dòng log | "ai đổi gì lúc nào?" | ghi gấp ~5 lần với audit cả hàng (ex09) |
| Temporal / SCD2 | mỗi phiên bản là một dòng với `[valid_from, valid_to)` | "giá tại ngày X?" | bảng lớn dần, query phải lọc theo khoảng |
| Event sourcing | chỉ lưu sự kiện, trạng thái suy ra | mọi thứ | phức tạp; ngoài phạm vi buổi này |

Postgres **không có temporal table** theo chuẩn SQL:2011 (`FOR SYSTEM_TIME`). Dùng range type + exclusion constraint (phần 4) hoặc extension bên thứ ba.

## 2. Soft delete
```sql
UPDATE accounts SET deleted_at = now() WHERE id = 2;           -- xóa mềm
CREATE VIEW active_accounts AS SELECT id, email, name FROM accounts WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX ON accounts (lower(email)) WHERE deleted_at IS NULL;  -- unique chỉ cho dòng còn sống
```
- Mọi query phải nhớ `deleted_at IS NULL`: đưa vào **view** (hoặc RLS, R09) để khỏi quên.
- `UNIQUE` thường làm email đã xóa chặn mãi việc đăng ký lại → partial unique index.
- **FK không biết `deleted_at`**: đơn hàng vẫn trỏ tới user đã xóa; ở `shop_*` có 24/1000 user bị xóa mềm và vẫn có đơn *sau* thời điểm xóa (ex08). Quyết định nghiệp vụ: chặn tạo đơn (CHECK/trigger/app), hay chấp nhận.
- Index và thống kê vẫn chứa dòng đã xóa; `count(*)` trên bảng gồm cả chúng. Bảng có tỉ lệ xóa cao nên có partial index `WHERE deleted_at IS NULL`.
- Soft delete **không** phải xóa theo luật (GDPR/xóa dữ liệu cá nhân): dữ liệu vẫn còn. Cần job xóa/ẩn danh thật sau thời hạn giữ.

## 3. Audit log bằng trigger
```sql
CREATE FUNCTION audit_product() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN INSERT INTO product_audit (op, row_id, new_row) VALUES (TG_OP, NEW.id, to_jsonb(NEW));
  ELSIF TG_OP = 'UPDATE' THEN INSERT INTO product_audit (op, row_id, old_row, new_row) VALUES (TG_OP, NEW.id, to_jsonb(OLD), to_jsonb(NEW));
  ELSE INSERT INTO product_audit (op, row_id, old_row) VALUES (TG_OP, OLD.id, to_jsonb(OLD)); END IF;
  RETURN NULL;
END $$;
CREATE TRIGGER products_audit AFTER INSERT OR UPDATE OR DELETE ON products FOR EACH ROW EXECUTE FUNCTION audit_product();
```
- `TG_OP`, `OLD`, `NEW`: OLD không có khi INSERT, NEW không có khi DELETE. `to_jsonb(NEW)` lưu cả dòng, thêm cột không cần sửa trigger.
- **ROW-level** để thấy từng dòng; STATEMENT-level cần transition table (`REFERENCING NEW TABLE AS …`) để xem tập dòng.
- `WHEN (OLD.* IS DISTINCT FROM NEW.*)` bỏ qua UPDATE không đổi gì (ORM hay ghi lại cả dòng). `IS DISTINCT FROM` an toàn với NULL; `<>` thì không.
- Người thực hiện: `current_user` thường là user kết nối chung của app. Ghi người dùng thật bằng `SET LOCAL app.user_id = '…'` rồi đọc `current_setting('app.user_id', true)` trong trigger.
- Trigger chạy **trong cùng transaction** với thay đổi: rollback thì audit cũng mất (đúng), nhưng ghi chậm đi (ex09). Superuser vẫn có thể `DISABLE TRIGGER` hoặc sửa bảng audit; audit "chống giả mạo" cần thêm phân quyền (O01) hoặc đẩy ra hệ thống ngoài.
- Dựng lại trạng thái tại T: với mỗi `row_id` lấy sự kiện mới nhất có `changed_at <= T`, bỏ nếu là DELETE (ex04).

## 4. Temporal: SCD type 2 và khoảng thời gian
SCD (slowly changing dimension) type 1 = ghi đè (mất lịch sử); **type 2 = mỗi thay đổi là một dòng mới** với khoảng hiệu lực.
```sql
price_history(product_id, price, valid_from timestamptz, valid_to timestamptz)  -- valid_to NULL = đang hiệu lực, khoảng [from, to)
-- giá tại thời điểm t
... ph.valid_from <= t AND t < coalesce(ph.valid_to, 'infinity')
-- đổi giá nguyên tử
WITH closed AS (UPDATE price_history SET valid_to = now() WHERE product_id = 1 AND valid_to IS NULL RETURNING product_id)
INSERT INTO price_history SELECT product_id, 160, now(), NULL FROM closed;
```
- **Nửa mở `[from, to)`**: mỗi thời điểm thuộc đúng một khoảng, kể cả đúng lúc đổi giá. `BETWEEN` đóng hai đầu làm điểm biên khớp hai dòng → nhân đôi dòng khi JOIN (ex05).
- Ép "không chồng nhau": `EXCLUDE USING gist (product_id WITH =, tstzrange(valid_from, valid_to) WITH &&)` cần extension `btree_gist` (đã có trong `lab`) (ex07). UNIQUE/PK không làm được việc này.
- **Bitemporal** có thêm trục "thời điểm hệ thống biết" (`recorded_at`), để trả lời "tại ngày X, ta tưởng giá là bao nhiêu?". Nhắc để biết, không luyện ở đây.
- Giá lúc bán trong `order_items.unit_price` (R01) là snapshot; SCD2 dùng khi cần truy vấn "giá tại ngày X" cho nhiều đối tượng hoặc báo cáo.

## Bẫy hay gặp
1. Quên điều kiện `deleted_at IS NULL` ở một chỗ → dữ liệu đã xóa quay lại.
2. UNIQUE thường cùng soft delete.
3. Audit trigger `FOR EACH STATEMENT` mà tưởng thấy từng dòng.
4. `BETWEEN` với khoảng thời gian → trùng ở điểm biên.
5. Đổi giá bằng hai câu lệnh không nguyên tử (khoảng trống hoặc hai dòng "hiện tại").
6. Audit không có chính sách giữ → bảng audit lớn hơn cả dữ liệu thật (ex09).

## Postgres-specific
- `OLD.* IS DISTINCT FROM NEW.*` so sánh cả bản ghi (dùng được trong `WHEN` của trigger). Range types (`tstzrange`) và `EXCLUDE` là đặc sản của Postgres.
- Từ Postgres 18, `RETURNING old.*, new.*` có thể trả cả giá trị cũ/mới của UPDATE ngay trong câu lệnh (đã thử ở R03 trên 18.6), dùng được để ghi audit ở tầng ứng dụng thay trigger.
