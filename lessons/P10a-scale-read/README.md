# P10a · Hiệu ứng quy mô (đọc)

Đọc khoảng 10 phút, rồi dành phần lớn thời gian cho thí nghiệm. Module này **không dạy khái niệm mới**: nó dùng P01–P09 để trả lời "query này sẽ ra sao khi dữ liệu ×100, ×1000?". Mỗi thí nghiệm có bước **dự đoán trước** (ghi ra giấy), rồi đo.

## Quy mô và giới hạn của phép đo (đọc kỹ)
- Bảng thí nghiệm là bảng tổng hợp `p10.t_*` (cùng cột, cùng phân phối) ở ba quy mô: `t_s` 10 000 dòng, `t_m` 1 000 000 dòng (`setup.sql`, ~5 giây), và `p10l.t_l` **10 000 000 dòng** (`setup-large.sql`, 1–2 phút, ~1.6 GB; **không phải `shop_l`**, nhưng cùng bậc 10M và đủ lớn để vượt `shared_buffers = 256MB`).
- Số liệu trong `solutions/*.md` do tôi đo trên Postgres 18.6, container 4 nhân, 15 GB RAM, cache của hệ điều hành đã ấm (page cache của OS vẫn che phần lớn I/O đĩa, nên "read" ở đây là đọc từ RAM của OS, không phải đĩa). Chạy trên máy bạn: **số buffers và plan tái hiện được, thời gian thì không**. Ba lần đo/ô, lấy lần nhanh nhất.
- `shop_l` (đủ 6 bảng, ~9 GB) chưa được dùng/verify trong bài; muốn kiểm trên `shop_l` thì sinh bằng `datasets/shop/build.sh l`.

## Mục tiêu: sau buổi này bạn làm được
- Dự đoán đúng xu hướng (≥ 70%) plan/buffers/thời gian của một query khi N tăng ×10 và ×100, và giải thích **điểm gãy** bằng số đo.
- Biết các điểm gãy chính: Seq ↔ Index/Bitmap (selectivity × correlation), Nested Loop ↔ Hash Join, sort/hash vừa/tràn `work_mem`, bảng vượt `shared_buffers`, O(n) ↔ O(log n).
- Nhận ra query "chạy tốt ở 10k, sụp ở 10M" trước khi nó lên production.

---

## 1. Ba lớp chi phí cần tách bạch
1. **Số page phải chạm** (BUFFERS): quyết định bởi plan; tuyến tính với N cho Seq Scan, gần hằng cho tra cứu index, tỉ lệ với số dòng khớp cho Index/Bitmap.
2. **Bộ nhớ làm việc** (`work_mem`): sort, hash join, hash aggregate, bitmap. Vượt → ghi file tạm (`temp written`), hoặc bitmap thành `lossy`.
3. **Cache**: `shared_buffers` (256 MB ở đây) và page cache của OS. Bảng nhỏ hơn cache: lần chạy thứ hai nhanh; lớn hơn: luôn đọc lại.

## 2. Điểm gãy Seq ↔ Index ↔ Bitmap
Đo trên cột `u` (đều, không tương quan với vị trí vật lý) và `ts` (tăng theo id, tương quan 1), **cùng truy vấn** `count(amount) WHERE u < X` ở ba quy mô (hàng đầu là phần trăm bảng được lấy):

| lấy | `t_s` 10k (plan, buffers) | `t_m` 1M | `t_l` 10M |
|---|---|---|---|
| 0.01% | Index Scan, 3 | Bitmap, 100 | Bitmap, 1 022 |
| 0.1% | Bitmap, 15 | Bitmap, 956 | Bitmap, 9 739 |
| 1% | Bitmap, 71 | Bitmap, 6 453 | Bitmap, **64 441** |
| 10% | Bitmap, 106 | Bitmap, 10 553 | Bitmap, 104 266 |
| 50% | Seq Scan, 104 | Seq Scan, 10 310 | Seq Scan, 103 093 |

- Với `u`, số buffers tăng **tuyến tính theo N ở cùng phần trăm**: 1% bảng 10M là 64 441 page (62% bảng!). Bitmap Heap Scan chạm mọi page có ít nhất một dòng khớp; ở 1% mỗi page có ~1 dòng khớp (100 dòng/page × 1%), nên gần như mọi page đều dính.
- Điểm planner chuyển sang Seq Scan: giữa 40% và 50% ở `t_m`. Nhưng **điểm hòa vốn thật về thời gian đến sớm hơn khi N lớn**: ở `t_l`, 1% mất 312 ms, 10% mất 403 ms ≈ Seq Scan (402 ms).
- Với `ts` (tương quan 1) Index Scan thắng tới 60% ở `t_m`: các dòng liền nhau trong index nằm liền nhau trong heap (P03).
- `work_mem` ảnh hưởng cả Bitmap: ở `t_l` với 1%, bitmap vượt 4 MB nên `Heap Blocks: exact=33566 lossy=33219` và recheck loại **2 873 146** dòng thừa.

## 3. Join: Nested Loop ↔ Hash Join
Join `t_m` với `mid` (200 000 dòng, PK) theo `mid.id = t_m.amount + 1`, lọc `t_m` bằng `u < K` (K dòng phía ngoài). Planner chọn Nested Loop với K ≤ 10 000 và Hash Join từ K = 30 000. Đo thật (ép từng kiểu join):

| K | Nested Loop: ms / buffers | Hash Join: ms / buffers |
|---|---|---|
| 100 | **0.23** / 395 | 18.4 / 2 263 |
| 1 000 | **5.1** / 4 029 | 47.6 / 3 018 |
| 10 000 | **21.5** / 36 533 | 57.5 / 8 515 |
| 30 000 | 39.2 / 100 962 | 49.3 / 11 945 |
| 100 000 | 87.6 / 313 105 | **68.3** / 12 615 |
| 1 000 000 | 495 / 1 030 627 | **183** / 12 372 |

Hash Join có chi phí gần như hằng (đọc cả `mid` một lần); Nested Loop tăng tuyến tính theo K. Giao điểm về **buffers** ở K ≈ 3 000, về **thời gian** ở K ≈ 50 000 (cache nóng nên mỗi lần dò index rẻ). Cache lạnh hay đĩa chậm thì giao điểm thời gian dịch về gần giao điểm buffers.

## 4. Tràn bộ nhớ
Sắp `(amount, id)` của `t_m` (1M dòng) cần **46 MB** để không tràn (`work_mem = 45MB` vẫn ghi 6 612 page tạm, 46MB thì không). Chi phí tràn: `temp written` (I/O), không nhất thiết chậm hơn nhiều: xem ex05 để biết số đo thật và vì sao.

## 5. Cache
`shared_buffers = 256MB` = 32 768 page. Seq Scan bảng lớn hơn 1/4 shared_buffers dùng **ring buffer** (256 kB): quét `t_m` (80 MB) hai lần liên tiếp, lần hai vẫn `read=11 176` và chỉ 376 page của `t_m` nằm trong shared_buffers. Seq Scan không bao giờ làm "ấm" cache; Bitmap/Index Scan thì có (xem ex06).

## 6. O(n) ↔ O(log n)
`WHERE id = 777`: 3 → 4 → 4 buffers ở 10k → 1M → 10M. `count(*)`, `max(amount)` (không index), top-10 theo cột không index: tuyến tính theo N (ex07).

## Bẫy hay gặp
1. Kết luận từ dữ liệu 10k: plan khác, `work_mem`/cache khác.
2. Chỉ so thời gian giữa hai quy mô: cache ấm làm đảo thứ tự (Nested Loop "thắng" tới K = 50 000 dù chạm nhiều page gấp 8×).
3. Nghĩ "có index là nhanh": 1% của 10M dòng vẫn là 64 441 page với index không tương quan.
4. Quên rằng chi phí `ORDER BY … LIMIT` phụ thuộc vị trí các dòng khớp, không phải N (ex08).

## Đo bằng gì
- `EXPLAIN (ANALYZE, BUFFERS)` (buffers, `temp written`, `Heap Blocks … lossy`), `bench/bench.sh` cho chạy nhiều quy mô (`shop_*`), `pg_buffercache`, `SET work_mem`, `SET enable_*` (chỉ để thí nghiệm).
