# Báo cáo nhóm `p` (P01–P10b)

Branch `content/p`. Môi trường verify: Postgres **18.6** (Docker `postgres:18`, compose của workspace; 4 nhân, 15 GB RAM, `shared_buffers = 256MB`, `work_mem = 4MB`, `timezone = UTC`). Dữ liệu: `shop_xs`, `shop_s`, `shop_m` (đã sinh bằng `datasets/shop/build.sh`). **`shop_l` không được sinh** (đúng brief); thay vào đó bài P10 dùng bảng tổng hợp 10M dòng `p10l.t_l` trong `lab` (xem dưới).

Kết quả `bash tools/verify.sh` trên cả 11 thư mục: **71 bài đạt · 18 bài manual (demo chạy được) · 0 lỗi**. Mọi `trap*` bị chấm SAI, mọi `alt*` được chấm ĐÚNG.

## Module và trạng thái

| Module | Thư mục | Bài | Tự chấm (check/query) | Manual (số đo thật) | Verify |
|---|---|---|---|---|---|
| P01 Storage | `P01-storage` | 9 | ex01–08 | ex09 | 🧪 trên 18.6 |
| P02 B-tree | `P02-btree-index` | 9 | ex01–08 (shop_m) | ex09 | 🧪 |
| P03 EXPLAIN | `P03-explain` | 9 | ex01–08 (lab) | ex09 | 🧪 |
| P04 Planner/stats | `P04-planner-statistics` | 8 | ex01–07 | ex08 | 🧪 |
| P05 GIN/GiST/BRIN | `P05-gin-gist-brin` | 7 | ex01–06 | ex07 | 🧪 |
| P06 Transactions | `P06-transactions` | 7 | ex01–06 (2 session) | ex07 | 🧪 |
| P07 MVCC/VACUUM | `P07-mvcc-vacuum` | 8 | ex01–07 | ex08 | 🧪 |
| P08 Locks | `P08-locks` | 7 | ex01–05 (2+ session) | ex06, ex07 | 🧪 |
| P09 Anti-patterns | `P09-anti-patterns` | 9 | ex01–08 | ex09 | 🧪 |
| P10a Scale (đọc) | `P10a-scale-read` | 8 | ex01, 03, 04, 08 | ex02, 05, 06, 07 | 🧪 |
| P10b Scale (ghi/vận hành) | `P10b-scale-write` | 8 | ex03, 04, 07, 08 | ex01, 02, 05, 06 | 🧪 |

Mỗi bài tự chấm có `solutions/exNN.sql` (+ `.check.sql` hoặc `.state`/query), tối thiểu 1 `trap` (đa số 2–3) và nhiều bài có `alt`. Mỗi bài manual có `solutions/exNN.sql` (demo chạy được, `verify.sh` đã chạy) và `exNN.md` với **số đo thật**.

## Cái gì CHƯA verify (ghi rõ)
- **`shop_l` (10M, 6 bảng): chưa sinh, chưa verify.** Mọi chỗ ghi "dự đoán cho shop_l" trong `solutions/*.md` là ngoại suy, đã ghi "chưa verify".
- **Bảng 10M thay thế (`p10l.t_l`):** P10a/P10b đo quy mô "l" trên một bảng hẹp tổng hợp 10 000 000 dòng (`lessons/P10a-scale-read/setup-large.sql`, 805 MB heap + 516 MB index, ~50 giây để sinh). **Không phải `shop_l`**: cùng bậc 10M và vượt `shared_buffers` nhưng khác độ rộng/số bảng/skew. `check` không bao giờ dùng nó (chỉ `s`/`m`), nên `verify.sh` không phụ thuộc.
- Tính năng riêng của 18 dùng trong bài (đã chạy thật trên 18.6): dòng `Index Searches:` trong EXPLAIN (P02, P03), `BUFFERS` mặc định với `ANALYZE` (P03), skip scan (P02 README, đo thật: 13 lần tìm, 79 buffers). `EXPLAIN (SERIALIZE)` (P09 ex05) là tính năng của 17+; **Postgres 16 sẽ không chạy được ex05 và các phần "Index Searches"**.
- Cache của hệ điều hành luôn ấm: mọi số "read" là đọc từ page cache OS, không phải đĩa. Nói rõ ở README của P03, P10a, P10b. Chưa đo được ảnh hưởng của đĩa chậm.
- Thời gian đo là 1–7 lần chạy trên một máy chung 4 nhân; chỉ số **buffers/page/WAL/xid/dung lượng/loại plan** tái hiện được, **thời gian thì không**. Các check chỉ so buffers/plan/dung lượng với ngưỡng rộng, không so thời gian tuyệt đối (ngoại lệ: các check dùng `sleep` để ép xen kẽ 2 session và đo "khoảng lặng của writer" ở P10b ex04/ex07 với ngưỡng 1.0 s so với 5.7 s của cách sai).

## Số đo thật đã dùng (tóm tắt, chi tiết ở từng `solutions/*.md`)
- P01: `orders` 98.3 B/dòng; 11 929 page ở 1M; TOAST 2 300 page cho 300 giá trị 60 KB; padding 417 → 319 page; HOT 12/200 → 200/200 sau fillfactor 70 + CLUSTER.
- P02: tra PK 3 → 4 buffers (10k → 1M), Seq Scan `user_id` 120 → 11 929; sai thứ tự cột 524 vs 7 buffers; INCLUDE 11 445 → 222; partial index 22.5 MB → 0.76 MB; BRIN 71 072 kB → 32 kB.
- P03: plan thật của `lab.p03` (parallel, Bitmap/Index, Nested Loop, Hash batch 8, Sort external merge 7072 kB vs quicksort 21 664 kB; ước lượng 4 vs 400); `bench` join-agg xs/s/m.
- P04: `pg_stats` shop_s; sai ước lượng 1 vs 100 000, 47 vs 137, 21 vs 1 000, 568 vs 20 000, 20 000 vs 1 000 nhóm; ANALYZE 22 ms → 137 ms; `n_distinct` thấp 2.3–4.4× ở 1M.
- P05: GIN 44 buffers, trigram GIN 45/GiST 417/Seq 1 526, FTS 10 vs 398, GiST range 4 vs 2 206; kích thước/thời gian build B-tree/BRIN/GIN ở 10k và 1M; BRIN trên bảng xáo trộn quay về Seq Scan.
- P06: kết quả anomaly thật của hai session; `pgbench` 8 client: READ COMMITTED 4 614 tps, RR/SERIALIZABLE lỗi 60.9% / 60.6% ở 4 dòng nóng, 0.57% ở 1 000 dòng.
- P07: `heap_page_items`, `pgstattuple` (4 545 page, 78% lãng phí, VACUUM giữ nguyên file, VACUUM FULL 1 137 page); UPDATE ×4 ở 1M: 11 980 → 47 735 page, VACUUM 1.04 s, VACUUM FULL 2.30 s.
- P08: lock mode thật từ `pg_locks`, log deadlock thật, `pgbench` hàng đợi FOR UPDATE 286/325/318 tps vs SKIP LOCKED 275/957/1 403 tps (1/4/8 worker).
- P09: bảng 8 anti-pattern trước → sau (buffers); `OFFSET` 0 → 900 000: 4 → 14 199 buffers, keyset 4.
- P10a: sweep selectivity s/m/l, join NL ↔ Hash (buffers hòa ở K≈3 000, thời gian ở K≈50 000), sort/hash spill 4MB/64MB/1GB (spill không chậm hơn ở môi trường này), `pg_buffercache` (ring buffer), O(n) vs O(log n), pathological `ORDER BY … LIMIT` 137 → 13 396 → 133 915 buffers.
- P10b: nạp 100k dòng: 39.5–41.9 s (từng dòng) vs 0.22–0.27 s (`INSERT … SELECT`/`COPY`); 0 → 5 index phụ: 2 s → 19 s, WAL 170 → 600 MB; `ALTER TABLE` rewrite 23.2 s ở 10M; CREATE INDEX 3.2 s vs CONCURRENTLY 5.1 s; UPDATE toàn bảng 10M 114.9 s, VACUUM 13.5 s, ANALYZE 0.45 s.

## Quyết định thiết kế đáng chú ý
- **Hai session trong `check`:** `check.sh` chạy một `psql`; bài làm có dòng `-- >>> B` (hoặc tham số `:me`, `:from/:to`) và `check.sql` dựng session phụ bằng `\! { psql … ; exit 0; } … &` + `sleep`, tách bài làm bằng `split_part` rồi chạy từng đoạn qua `\gexec`. Dùng ở P06 ex03–06, P07 ex05, P08 ex02–05, P10b ex04/07. Không cần dblink.
- **Phát hiện quan trọng khi chạy trong Docker:** postgres là PID 1 của container, tiến trình `psql` chạy nền bị mồ côi và được gán cho postmaster; khi nó thoát với mã ≥ 2 (ví dụ bị `pg_terminate_backend`), postmaster coi là child crash và **khởi động lại cả cluster** (log "untracked child process … exited with exit code 2 / terminating any other active server processes"). Mọi session phụ vì thế được bọc `{ …; exit 0; }`. Đề xuất (chưa làm vì ngoài phạm vi): thêm `init: true` cho service trong `env/docker-compose.yml`.
- **Số liệu tất định:** `shop_s` (10k) nhỏ hơn mẫu ANALYZE 30 000 nên `pg_stats` chính xác; các bảng `lab.p0x` dùng `hashint4`/công thức, không `random()`. Bài dựa trên mẫu ngẫu nhiên (P04) được chạy 5–8 lần để kiểm độ ổn định và dùng ngưỡng rộng (đã đổi tag 250 → 180 vì tag 250 flaky ở target 300).
- **Đáp án "động":** nhiều bài đọc plan (P03 ex07, P10a ex01/03) lấy đáp án đúng từ `EXPLAIN` trong check thay vì cố định, nên không vỡ khi thống kê dao động.
- **`EXPLAIN (ANALYZE)` thường không thấy chi phí detoast**; P09 ex05 dùng `SERIALIZE`.
- Trường hợp `NOT IN` (P09 ex08) check không chạy câu sai (hàng giờ): kiểm plan bằng `EXPLAIN` (không ANALYZE) và từ chối nếu còn `SubPlan`.
- P10 là hai thư mục `P10a-scale-read` và `P10b-scale-write`, mỗi cái có `setup.sql` riêng (schema `p10`, `p10b`); `setup-large.sql` (schema `p10l`) tách riêng để `-- reset` không xóa bảng 10M.

## Thay đổi ở `tools/`
Không sửa `check.sh`, `verify.sh`, `lib.sql`, `pg-runner.sh`. Chỉ cập nhật `tools/CONTENT_PLAN.md` (dòng P) và thêm `tools/reports/p.md`. Mọi hàm tiện ích (`scan_of`, `join_of`, `am_of`, `spill`, `ser`) định nghĩa cục bộ trong từng `check.sql` để tránh xung đột khi nhiều nhóm sửa `lib.sql`.
Thêm kết quả bench: `bench/results/2026-10-18-p02-pk-lookup.md`, `…-p02-user-lookup-noindex.md`, `…-p03-join-agg.md`.

## Việc còn lại / đề xuất cho người duyệt
- **Push và PR chưa làm được:** môi trường cloud này không có remote (`git remote` rỗng, `GH_TOKEN` không hợp lệ), nên branch `content/p` chỉ có commit cục bộ. Cần push `content/p` và mở PR vào `main` từ máy có quyền.
- Không sửa `ROADMAP.md`. Gợi ý: pass criterion của P10 ("dự đoán đúng ≥ 70%") là tiêu chí tự đánh giá, không chấm được bằng máy.
- Chạy `verify.sh` toàn bộ nhóm P mất ~12–15 phút (P10b, P08, P06 có `sleep`); không chạy hai `verify.sh` song song vì dùng chung DB `lab`.
- Nếu muốn có số liệu thật cho `shop_l`: `bash datasets/shop/build.sh l` (~9 GB, ~10 phút) rồi chạy lại các bảng đo của P02, P03, P09 với `--scales l`.
