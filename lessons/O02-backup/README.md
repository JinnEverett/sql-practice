# O02 · Backup: pg_dump, WAL, PITR, kiểm thử restore

Đọc khoảng 10 phút. Mọi lệnh chạy trong container (`docker exec sql-practice-pg …`) hoặc bằng `pitr-lab.sh` (dựng container riêng, không đụng DB bài tập). Số đo trong bài lấy trên Postgres 18.6, 4 CPU.

## Mục tiêu: sau buổi này bạn làm được
- Chọn đúng loại backup: **logical** (`pg_dump`) hay **physical** (`pg_basebackup` + WAL).
- Dùng 3 định dạng dump, restore song song và chọn lọc một bảng.
- Dựng PITR (point-in-time recovery) và khôi phục tới trước một sự cố.
- Kiểm tra backup bằng `pg_verifybackup` và bằng restore thử; nói được RPO/RTO của từng cách.

---

## 1. Hai họ backup
| | Logical (`pg_dump`) | Physical (`pg_basebackup` + WAL) |
|---|---|---|
| Nội dung | câu lệnh/`COPY` dựng lại dữ liệu | bản sao file của cluster |
| Phạm vi | một DB, một schema, một bảng | cả cluster |
| Restore | nạp dữ liệu + **dựng lại index** (chậm khi lớn) | copy file + replay WAL (nhanh hơn) |
| Chéo phiên bản | được (dump 16 → restore 18) | không (cùng major version) |
| PITR | không | **có** (nếu lưu WAL liên tục) |
| RPO điển hình | khoảng giữa hai lần dump | vài chục giây – vài phút |

## 2. pg_dump
```bash
pg_dump -Fc -f m.dump shop_m              # custom: nén, pg_restore chọn lọc/song song
pg_dump -Fd -j4 -f m.dir shop_m           # directory: dump song song
pg_dump -Fp shop_m > m.sql                # plain SQL, đọc được bằng mắt
pg_dumpall --globals-only > globals.sql   # role, tablespace (không nằm trong pg_dump)
pg_restore -l m.dump                      # xem danh mục
pg_restore -j4 -d newdb m.dump            # restore song song
pg_restore -d newdb -a -t users m.dump    # chỉ dữ liệu bảng users
```
- `pg_dump` lấy snapshot nhất quán (một transaction `REPEATABLE READ`), nên dump đúng tại thời điểm bắt đầu dù có ghi đồng thời. Nó không chặn ghi nhưng giữ snapshot lâu (ảnh hưởng VACUUM, P07).
- Nén chiếm phần lớn thời gian dump (ex01). `-Z0` hoặc `-j` để nhanh hơn.
- Restore vào DB **trống mới tạo**, đừng đè lên DB đang chạy.

## 3. WAL, base backup, PITR
- Mọi thay đổi ghi vào **WAL** trước khi ghi vào file dữ liệu. Lưu WAL liên tục (`archive_mode=on` + `archive_command`) cộng một **base backup** là đủ để dựng lại trạng thái tại bất kỳ thời điểm nào sau base backup.
- Cấu hình nguồn: `wal_level=replica` (mặc định), `archive_mode=on`, `archive_command='test ! -f /archive/%f && cp %p /archive/%f'` (phải trả 0 khi và chỉ khi file đã an toàn), `archive_timeout` để ép đóng file WAL định kỳ.
- Base backup: `pg_basebackup -D dir -Fp -X stream -c fast`; kiểm tra: `pg_verifybackup dir`.
- Khôi phục: copy base backup vào data directory mới, đặt `restore_command='cp /archive/%f %p'`, `recovery_target_time='…'` (hoặc `recovery_target_lsn`, `recovery_target_xid`, `recovery_target_name`), `recovery_target_action='promote'`, tạo file `recovery.signal`, khởi động. Postgres replay WAL tới đích rồi mở ghi trên timeline mới.
- Chọn đích bằng cách đọc log ứng dụng/audit; quá đích thì làm lại từ base backup.

## 4. Backup chưa restore thử thì chưa là backup
- `pg_verifybackup` rẻ (0.35 s cho ≈ 1 GB) và bắt được file hỏng/thiếu, nhưng không thay thế restore thử.
- Tự động hóa restore thử định kỳ, kèm kiểm tra dữ liệu và ghi lại thời gian (RTO thực).
- Backup nằm cùng ổ/cùng máy với DB không bảo vệ khi mất máy. Lưu ở nơi khác, giữ nhiều thế hệ.

## 5. RPO và RTO
**RPO**: chấp nhận mất bao nhiêu dữ liệu. **RTO**: chấp nhận ngừng bao lâu. Dump hằng đêm: RPO ≈ 24 h. WAL archiving: RPO ≈ `archive_timeout`. Replication đồng bộ (O06): gần 0. RTO của logical backup tăng theo kích thước và số index (ex07).

## Đo bằng gì
`time`/`\timing` quanh lệnh, `ls -l`/`du -sh` cho kích thước, `pg_stat_archiver` (`archived_count`, `failed_count`, `last_archived_time`), `pg_current_wal_lsn()` và `pg_wal_lsn_diff()` để biết lượng WAL phát sinh, log server (`recovery stopping before commit…`).

## Bẫy hay gặp
1. Chỉ có `pg_dump` mà gọi là "PITR".
2. `archive_command` luôn trả 0 dù copy lỗi; WAL mất mà không biết (xem `pg_stat_archiver.failed_count`).
3. Archive WAL cùng đĩa với dữ liệu.
4. Quên role/globals khi chỉ dump một DB.
5. Restore thử trên cùng máy production làm đầy đĩa.
6. Không bao giờ restore thử.
7. Chọn `recovery_target_time` theo múi giờ nhầm (ghi rõ `+00`).

## Postgres-specific
- `pg_dump` chạy chéo phiên bản, physical backup thì không. MySQL tương đương: `mysqldump` (logical) và binlog (cho PITR).
- Công cụ vận hành thật: pgBackRest, WAL-G, Barman (nén, mã hóa, retention, restore song song).
