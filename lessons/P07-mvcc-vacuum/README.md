# P07 · MVCC & VACUUM

Đọc khoảng 10 phút. Ví dụ chạy trên `lab.p07` (`setup.sql`, các bảng tắt autovacuum để số đo tái hiện được) và `shop_m`, Postgres 18.6. Cần `pageinspect`, `pgstattuple`, `pg_visibility` (đã có trong image, `setup.sql` tự `CREATE EXTENSION`).

## Mục tiêu: sau buổi này bạn làm được
- Giải thích MVCC: mỗi `UPDATE`/`DELETE` **không sửa tại chỗ** mà tạo phiên bản dòng mới; `xmin`/`xmax` quyết định ai thấy phiên bản nào.
- Đo bloat bằng số thật (`pgstattuple`, `pg_relation_size`) và giải thích nó đến từ đâu.
- Phân biệt `VACUUM`, `VACUUM FULL`, autovacuum; biết vì sao VACUUM đôi khi "không dọn được".
- Hiểu HOT update và opportunistic pruning; hiểu XID wraparound và `VACUUM FREEZE`.

---

## 1. Phiên bản dòng (tuple version)
Mỗi phiên bản dòng có header với:
- `xmin`: ID transaction đã tạo nó;
- `xmax`: ID transaction đã xóa/cập nhật nó (0 nếu còn sống);
- `ctid`/`t_ctid`: trỏ tới phiên bản **mới hơn** (trỏ về chính nó nếu là bản mới nhất).

Một phiên bản **hiển thị** cho snapshot S nếu `xmin` đã commit trước S và `xmax` chưa commit (hoặc commit sau S). Đó là cơ chế ở P06: đọc không chặn ghi, ghi không chặn đọc.

`lab.p07.ver`: 3 dòng; dòng `id = 1` bị UPDATE 3 lần, dòng `id = 3` bị DELETE. Đọc trực tiếp page 0 bằng `heap_page_items(get_raw_page('p07.ver', 0))`:

| lp | `t_ctid` | `xmax ≠ 0` | `HOT_UPDATED` | `HEAP_ONLY` | là gì |
|---|---|---|---|---|---|
| 1 | (0,4) | có | có | không | `id=1` phiên bản gốc, đã bị thay |
| 2 | (0,2) | không | không | không | `id=2` nguyên vẹn |
| 3 | (0,3) | có | không | không | `id=3` đã bị DELETE (ctid trỏ về chính nó) |
| 4 | (0,5) | có | có | có | `id=1` lần UPDATE 1, đã bị thay |
| 5 | (0,6) | có | có | có | `id=1` lần UPDATE 2, đã bị thay |
| 6 | (0,6) | không | không | có | `id=1` bản **hiện tại** |

Dòng `id=1` có 4 phiên bản (lp 1 → 4 → 5 → 6) nhưng chỉ một còn sống. Bảng 3 dòng mà page có 6 tuple.

## 2. Bloat và VACUUM
Phiên bản chết không biến mất khi commit: chúng chiếm chỗ trong heap **và trong index** cho tới khi `VACUUM` thu hồi (khi không snapshot nào còn có thể thấy chúng).
- **Opportunistic pruning**: khi page "gần đầy", bất kỳ truy vấn nào chạm page cũng dọn chuỗi HOT chết ngay tại page (không cần VACUUM). Nó giải phóng chỗ trong page nhưng không dọn index.
- **`VACUUM`** (thường): quét heap, đánh dấu chỗ của tuple chết là dùng lại được (free space map), dọn entry index trỏ tới chúng. **Không khóa chặn đọc/ghi**. **Không trả file cho hệ điều hành** (trừ phần trống ở cuối file).
- **`VACUUM FULL`** (và `CLUSTER`): ghi lại **toàn bộ bảng + index** sang file mới gọn. Giữ khóa `ACCESS EXCLUSIVE` (chặn cả `SELECT`) suốt thời gian chạy và cần chỗ trống bằng kích thước bảng mới.

Đo trên `lab.p07.bloat` (100 000 dòng, mỗi dòng bị UPDATE 3 lần, index trên cột bị sửa nên không HOT):

| trạng thái | page heap | dead tuples | live % | free % | index `val` (page) |
|---|---|---|---|---|---|
| sau 3 lần UPDATE | **4 545** | 100 000 | 22.3 | 48.1 | 825 |
| sau `VACUUM` | 4 545 | 0 | 22.3 | **75.0** | 825 |
| sau `VACUUM FULL` | **1 137** | 0 | 89.1 | 0.9 | **276** |

Bảng sống chỉ cần ~1 137 page; heap có 4 545 page (**bloat 4×**, 78% lãng phí). Pruning đã tự dọn các thế hệ cũ nên chỉ còn 100 000 tuple chết (thế hệ cuối) cùng 48% chỗ trống. `VACUUM` đưa dead về 0 nhưng **file vẫn 4 545 page**: chỗ trống chỉ để các UPDATE sau dùng lại.
`pgstattuple('bảng')` cho chính xác nhưng quét cả bảng (đắt); với bảng lớn dùng `pgstattuple_approx` hoặc ước lượng từ `pg_stat_user_tables.n_dead_tup`.

## 3. VACUUM không dọn được: xmin horizon
VACUUM chỉ thu hồi phiên bản chết **mà không snapshot nào còn thấy được**. Một transaction mở lâu (`REPEATABLE READ`, hoặc `idle in transaction`, replication slot lag, prepared transaction bị bỏ quên) giữ `backend_xmin` cũ → chặn dọn mọi dòng chết **sau** thời điểm đó, ở mọi bảng của DB. Dấu hiệu: `n_dead_tup` tăng dù autovacuum chạy; `VACUUM VERBOSE` báo "N dead row versions cannot be removed yet". Truy vết: `SELECT pid, state, xact_start, backend_xmin FROM pg_stat_activity WHERE backend_xmin IS NOT NULL ORDER BY xact_start;` (ex05). Phòng: `idle_in_transaction_session_timeout`.

## 4. Autovacuum
Autovacuum chạy VACUUM khi `dead tuples > autovacuum_vacuum_threshold (50) + autovacuum_vacuum_scale_factor (0.2) × reltuples`. Với bảng 1M dòng: > 200 050 dead; bảng 20M dòng: > 4 000 050 dead (ex07). Thêm `autovacuum_vacuum_insert_*` (1000 + 0.2 × reltuples dòng mới) để bảng chỉ INSERT vẫn được VACUUM (đặt visibility map, freeze). Mặc định `autovacuum_vacuum_cost_delay = 2ms`, `vacuum_cost_limit = 200`: autovacuum tự giảm tốc để không chiếm hết I/O. Với bảng nóng đặt tham số riêng: `ALTER TABLE … SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 1000)`.

## 5. HOT update và fillfactor (nhắc lại P01)
`UPDATE` không đổi cột có index **và** page còn chỗ → phiên bản mới nằm cùng page, không thêm entry index, và pruning dọn được tại chỗ. `UPDATE` đổi cột có index (như `val` ở trên) không bao giờ HOT: mỗi lần thêm entry vào mọi index, nên index phình (825 page cho 100 000 dòng, sau VACUUM FULL chỉ còn 276).

## 6. XID wraparound
`xid` chỉ 32 bit; Postgres so sánh vòng tròn, mỗi transaction "thấy" 2³¹ xid trước nó. Phiên bản cũ phải được **freeze** (đánh dấu "luôn là quá khứ") trước khi chúng đi quá nửa vòng, nếu không dữ liệu "biến mất". Cơ chế:
- `vacuum_freeze_min_age` (50M): VACUUM freeze tuple già hơn ngưỡng này;
- `autovacuum_freeze_max_age` (200M): bảng có `age(relfrozenxid)` vượt ngưỡng sẽ bị autovacuum **chạy bắt buộc (anti-wraparound)**, kể cả khi autovacuum bị tắt, nặng và không bỏ qua được;
- `vacuum_failsafe_age` (1.6B): VACUUM bỏ giảm tốc và **bỏ qua dọn index** để freeze cho kịp; khi chỉ còn ~3 triệu xid, Postgres từ chối giao dịch ghi mới.
Theo dõi: `SELECT datname, age(datfrozenxid) FROM pg_database;` và `age(relfrozenxid)` từng bảng. `VACUUM (FREEZE)` freeze chủ động (ex06), nên chạy ngoài giờ cao điểm trên bảng lịch sử lớn. Trên bảng chỉ INSERT: `pg_visibility_map_summary` cho biết bao nhiêu page đã `all_frozen`.

## Bẫy hay gặp
1. `VACUUM FULL` trên production giữa giờ: khóa `ACCESS EXCLUSIVE`. Dùng `pg_repack` (extension ngoài) hoặc thiết kế lại (partition + drop).
2. Tưởng VACUUM trả dung lượng đĩa.
3. Transaction mở lâu trên replica/báo cáo chặn VACUUM của primary (nếu `hot_standby_feedback = on`).
4. UPDATE hàng loạt toàn bảng: dung lượng nhân đôi (phiên bản mới + cũ) cho tới khi vacuum, kèm WAL lớn.
5. Chỉ nhìn `n_dead_tup` mà không nhìn index bloat.
6. Tắt autovacuum "cho đỡ tải": sớm muộn thành bloat hoặc anti-wraparound lúc cao điểm.

## Đo bằng gì
- `pgstattuple`, `pg_relation_size`, `pg_stat_user_tables` (`n_dead_tup`, `last_autovacuum`), `pg_stat_activity` (`backend_xmin`), `pageinspect` (`heap_page_items`), `pg_visibility_map_summary`, `age(relfrozenxid)`.
- Giới hạn của phép đo: bảng bài tập tắt autovacuum và chạy trong container nên số liệu tái hiện được; production có autovacuum và I/O khác nên thời gian khác, còn **số page, tỉ lệ bloat, số dead tuple** thì giống.
