# R12 · Bảng lớn: partitioning & time-series

Đọc khoảng 10 phút. Mọi bài chạy trên DB `lab`, schema `r12` (tạo bởi `setup.sql`; `events_p` mặc định 60 000 dòng, đổi bằng `psql -v n=1000000 -f setup.sql`). Cần index (P02) và EXPLAIN (P03).

## Mục tiêu: sau buổi này bạn làm được
- Tạo bảng partition theo **RANGE**, **LIST**, **HASH** và biết khi nào chọn loại nào.
- Viết truy vấn để **partition pruning** hoạt động, và kiểm bằng `EXPLAIN`.
- Vận hành: retention bằng `DETACH`/`DROP`, tạo partition trước, gắn bảng có sẵn vào bảng partition không quét lại.
- Làm rollup time-series idempotent.
- Hiểu **khi nào partition giúp và khi nào chỉ thêm chi phí**, bằng số đo.

---

## 1. Partition là gì
Một bảng logic (bảng cha, `PARTITION BY …`) gồm nhiều bảng vật lý (partition). Bạn `INSERT`/`SELECT` trên bảng cha; Postgres định tuyến dòng vào partition theo **khóa partition**.
| Kiểu | Khi dùng | Ví dụ |
|---|---|---|
| `RANGE` | khoảng liên tục, đặc biệt là thời gian | `events` theo tháng |
| `LIST` | tập giá trị rời rạc, ổn định | `orders` theo `region` |
| `HASH` | không có khóa tự nhiên để chia, muốn chia đều | `logs` theo `tenant_id`, `MODULUS 4` |
Khoảng RANGE là **nửa mở** `[from, to)`. Partition `DEFAULT` hứng giá trị còn lại (không có thì dòng ngoài mọi khoảng bị từ chối, lỗi 23514).

## 2. Ràng buộc và giới hạn
- **PK/UNIQUE phải chứa khóa partition** (không có index toàn cục): `PRIMARY KEY (id, ts)`. Hệ quả: `id` đơn lẻ **không** được database đảm bảo duy nhất (ex03); phải sinh `id` từ sequence/UUID dùng chung.
- FK **từ** bảng partition sang bảng khác: được. FK **trỏ tới** bảng partition: được từ Postgres 12, nhưng khóa tham chiếu phải gồm khóa partition.
- Index tạo trên bảng cha tự tạo trên từng partition (và partition mới); `CREATE INDEX CONCURRENTLY` không dùng được trên bảng cha, phải làm từng partition rồi `ATTACH`.
- Số partition lớn tốn: lập kế hoạch ∝ số partition (ex09), `max_locks_per_transaction`, bộ nhớ. Dưới vài trăm là ổn.

## 3. Partition pruning
Planner loại các partition mà khoảng của chúng không giao với điều kiện. Điều kiện phải so sánh **trực tiếp cột khóa** với hằng hoặc tham số (`ts >= … AND ts < …`). Bọc cột trong hàm (`date_trunc('month', ts) = …`, `ts::date = …`, `ts AT TIME ZONE …`) làm mất pruning (ex02).
- Pruning lúc **lập kế hoạch** với hằng; lúc **chạy** với tham số/biến (prepared statement, nested loop): `EXPLAIN` hiện `Subplans Removed` hoặc `(never executed)`.
- Kiểm bằng `EXPLAIN` xem những partition nào còn trong plan. Tham số `enable_partition_pruning` mặc định bật.
- Múi giờ: partition theo UTC, "tháng 3 giờ Việt Nam" giao với 2 partition (ex02).

## 4. Vận hành
- **Retention:** `ALTER TABLE parent DETACH PARTITION p; DROP TABLE p;` thay cho `DELETE`: không dead tuple, không `VACUUM`, WAL ~10 KB (ex05, ex09). Dùng `DETACH PARTITION … CONCURRENTLY` (14+) khi có truy vấn dài.
- **Tạo partition trước:** hàm/job định kỳ tạo partition 1–3 tháng tới (ex08). Đừng để dòng rơi vào `DEFAULT` rồi mới tạo partition cho khoảng đó (sẽ lỗi vì DEFAULT đã chứa dòng thuộc khoảng).
- **Gắn bảng có sẵn:** `ADD CONSTRAINT CHECK (khoảng) NOT VALID` → `VALIDATE` → `ATTACH PARTITION` (không phải quét lại) (ex06).
- **Di chuyển dữ liệu vào bảng partition:** tạo bảng partition mới, nạp theo lô, đổi tên; hoặc `ATTACH` bảng cũ làm partition đầu tiên rồi chia tiếp.

## 5. Time-series: rollup
Dữ liệu thô tăng không ngừng; dashboard đọc bảng tổng hợp (theo giờ/ngày) thay vì quét dữ liệu thô. Rollup phải **idempotent**: `INSERT … ON CONFLICT (khóa, ngày) DO UPDATE` ghi đè bằng số vừa tính lại cho các ngày **đã đóng** (ex07); chạy bù hay retry không làm đếm đôi. Giữ dữ liệu thô ngắn (partition + retention), dữ liệu tổng hợp dài hạn.
Với time-series nặng, cân nhắc extension (TimescaleDB) hoặc kho cột; ngoài phạm vi buổi này.

## Bẫy hay gặp
1. PK không chứa khóa partition (lỗi 0A000).
2. Điều kiện bọc hàm làm mất pruning.
3. Quên partition `DEFAULT`, hoặc để dòng rơi vào `DEFAULT` rồi mới thêm partition.
4. Quá nhiều partition nhỏ (planning chậm, lỗi `out of shared memory` khi `DROP` bảng cha).
5. Partition để "tăng tốc" truy vấn đã có index tốt: không nhanh hơn, tốn thêm (ex09).
6. Rollup cộng dồn vào số cũ (đếm đôi khi chạy lại) thay vì ghi đè.

## Postgres-specific
- Declarative partitioning từ Postgres 10 (kế thừa bảng kiểu cũ đã lỗi thời, đừng dùng); `HASH` từ 11; `DETACH … CONCURRENTLY` từ 14; PK/unique phải chứa khóa partition ở mọi phiên bản.
- Tên partition do bạn đặt (`events_p_2026_03`); xem danh sách: `SELECT inhrelid::regclass FROM pg_inherits WHERE inhparent = 'r12.events_p'::regclass`; ranh giới: `pg_get_expr(relpartbound, oid)`.
