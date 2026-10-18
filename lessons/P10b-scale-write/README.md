# P10b · Hiệu ứng quy mô (ghi & vận hành)

Đọc khoảng 10 phút, rồi làm thí nghiệm. Module này gom các thao tác **ghi và vận hành** mà chi phí phụ thuộc mạnh vào N: nạp dữ liệu, chi phí index khi ghi, tạo index, `ALTER TABLE`, UPDATE hàng loạt, VACUUM/ANALYZE, dung lượng. Mỗi thí nghiệm có bước **dự đoán trước**.

## Quy mô và giới hạn của phép đo
- Dùng lại bảng của P10a: `p10.t_s` (10k), `p10.t_m` (1M), `p10l.t_l` (10M, bảng tổng hợp tạo bằng `lessons/P10a-scale-read/setup-large.sql`, **không phải `shop_l`**). Các bài tự chấm dùng bảng 5 000–100 000 dòng trong `p10b`.
- Số đo: Postgres 18.6, container 4 nhân, 15 GB RAM, SSD, `synchronous_commit = on`, `shared_buffers = 256MB`, cache OS ấm. **Dung lượng, WAL, số xid, số dòng, loại khóa tái hiện được trên máy khác; thời gian thì không.** Mỗi thí nghiệm ghi rõ số lần chạy.
- `shop_l` (đủ 6 bảng) chưa được dùng/verify.

## Mục tiêu: sau buổi này bạn làm được
- Chọn cách nạp dữ liệu (`INSERT` từng dòng/lô/`INSERT … SELECT`/`COPY`) và ước lượng thời gian + xid cho 10M dòng.
- Định lượng "mỗi index thêm vào làm ghi chậm bao nhiêu" (write amplification) và quyết định index nào đáng giữ.
- Phân biệt DDL **tức thì** (chỉ catalog) và DDL **rewrite/quét** (tỉ lệ N), và biết thời gian lệnh = thời gian giữ khóa.
- Chạy DDL/backfill trên bảng lớn mà không chặn ghi: `CONCURRENTLY`, `NOT VALID` + `VALIDATE`, backfill theo lô.

---

## 1. Nạp dữ liệu
100 000 dòng vào bảng có PK (ex01):

| cách | thời gian |
|---|---|
| 100 000 `INSERT` autocommit | **39.5–41.9 s** |
| 100 câu `INSERT … VALUES` 1 000 dòng | 0.74–0.94 s |
| `INSERT … SELECT` | 0.22–0.27 s |
| `COPY` | 0.27 s |

Mỗi câu autocommit = 1 transaction = 1 xid = 1 lần chờ WAL flush. Gom lại: ~150× nhanh hơn, và tiêu 1 xid thay vì 100 000 (xid hữu hạn: P07). Ở 10M dòng, "từng dòng" ngoại suy ~65 phút.

## 2. Index trên đường ghi
Mỗi dòng mới ghi vào heap **và** mọi index (ex02). Nạp 1M dòng: chỉ PK 1.8–2.3 s, WAL ~170 MB; thêm 5 index phụ 18–20 s, WAL ~600 MB, index 168 MB (gấp 2 heap). Index thừa (P02 ex08, P05 ex06) cộng thẳng vào chi phí mọi lần ghi. Nạp một lần lớn: bỏ index phụ, nạp, tạo lại.

## 3. Tạo index
`CREATE INDEX` giữ `ShareLock` (chặn ghi) suốt lúc xây: 7 ms / 295 ms / 3.2 s ở 10k / 1M / 10M (tuyến tính). `CREATE INDEX CONCURRENTLY`: ghi vẫn chạy, chậm hơn 1.6–1.75× (5.1 s ở 10M), không chạy trong transaction, có thể để lại index `INVALID` nếu lỗi (ex04, ex05).

## 4. ALTER TABLE: tức thì hay không
| loại | ví dụ | tỉ lệ | khóa |
|---|---|---|---|
| chỉ catalog | `ADD COLUMN` (không default hoặc default hằng, từ PG 11) | O(1) (~1 ms) | `ACCESS EXCLUSIVE` chớp nhoáng |
| rewrite | `ADD COLUMN … DEFAULT random()`, `ALTER COLUMN TYPE` | O(N): 2.1 s / 23 s ở 1M / 10M | `ACCESS EXCLUSIVE` **suốt lệnh** |
| quét kiểm tra | `ADD CONSTRAINT CHECK`, `SET NOT NULL`, thêm FK | O(N): 0.08–0.11 s / 0.6–1.0 s ở 1M / 10M | `ACCESS EXCLUSIVE` suốt lần quét |
| chia đôi | `… NOT VALID` rồi `VALIDATE` | quét O(N) nhưng ghi vẫn chạy | `ShareUpdateExclusive` khi validate |

`ACCESS EXCLUSIVE` chặn cả `SELECT`, cộng hàng đợi lock (P08): một rewrite 23 giây = site đứng 23 giây. Với bảng lớn: luôn đặt `lock_timeout`, dùng `NOT VALID`, và backfill theo lô (ex07, ex08).

## 5. UPDATE hàng loạt, VACUUM, ANALYZE
UPDATE toàn bảng một câu nhân đôi dung lượng cho tới khi VACUUM (P07); chia lô và VACUUM chen vào giảm peak. ANALYZE đọc mẫu cố định nên gần như hằng, VACUUM tỉ lệ theo bảng (ex06).

## Bẫy hay gặp
1. Test migration trên bảng 10k dòng: mọi DDL đều "tức thì".
2. `CREATE INDEX` thường trên bảng đang ghi.
3. `ALTER COLUMN TYPE` trực tiếp trên bảng lớn thay vì thêm cột + backfill + đổi tên.
4. Một `UPDATE` khổng lồ để backfill: giữ khóa dòng lâu, WAL/bloat một khối, mất hết khi lỗi.
5. Dự đoán chi phí nạp bằng thời gian của một dòng × N mà quên index và xid.
6. Quên rằng thời gian đo hôm nay ở cache ấm: lần đầu chạy ở production có thể chậm hơn nhiều.

## Đo bằng gì
- `\timing`, `EXPLAIN (ANALYZE, BUFFERS)`, `pg_current_wal_lsn()` (chênh = WAL), `pg_relation_size`, `pg_total_relation_size`, `pg_indexes_size`, `txid_snapshot_xmax(txid_current_snapshot())` (số xid đã cấp), `pg_stat_activity`/`pg_locks`.
