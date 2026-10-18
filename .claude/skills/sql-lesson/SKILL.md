---
name: sql-lesson
description: |
  Dạy và cho luyện một module trong ROADMAP.md (S00, F01…F10, I01…I09, P01…P10, R01…R12, O01…O06). Tạo thư mục bài, viết lý thuyết ngắn, setup schema/seed, ra đề tăng dần độ khó, chạy bài làm trên Postgres và chấm.
  Triggers: /sql-lesson <ID>, "học module F05", "bài tiếp theo", "học window function", "dạy tôi về index"
---

# SQL Lesson: một buổi học theo module

Input là module ID (vd. `F05`). Nếu người học gọi bằng chủ đề thì tra `ROADMAP.md` để tìm ID tương ứng.
Tuân thủ toàn bộ quy tắc trong `CLAUDE.md`, đặc biệt là: **người học tự viết SQL** và **luôn chạy thật**.

## 0. Chuẩn bị
- Đọc dòng của module trong `ROADMAP.md` (nội dung chính, tiêu chí Pass).
- Đọc tracker và weaknesses. Lỗi nào liên quan đến module này thì lồng vào bài tập.
- Nếu `lessons/<ID>-*/` đã tồn tại thì đây là buổi **học tiếp**: đọc `review.md` và các `answers/` cũ, rồi bắt đầu từ bài chưa làm.
- Đổi trạng thái module trong tracker thành 🟡.

## 1. Warm-up (≤ 5')
2–3 câu hỏi ngắn lấy từ module trước hoặc từ weaknesses. Người học trả lời ngay trong chat, không cần tạo file.

## 2. Tạo thư mục bài
```
lessons/<ID>-<slug>/
  README.md        # lý thuyết cô đọng + mục tiêu buổi
  setup.sql        # tạo schema lab.<id> + seed (idempotent: DROP SCHEMA IF EXISTS ... CASCADE)
  exercises.md     # đề bài
  answers/         # người học ghi bài vào đây (ex01.sql, ex02.sql…)
  checks/          # query kiểm tra do Claude viết
```

### README.md (đọc trong ≤ 10')
- Mục tiêu: 3–5 gạch đầu dòng, viết dạng "sau buổi này bạn làm được…".
- Khái niệm: mỗi ý gồm 1 đoạn giải thích và 1 ví dụ chạy được trên dataset.
- Bẫy hay gặp: 3–5 bẫy, mỗi bẫy kèm query minh họa sai và đúng.
- Postgres-specific: những điểm khác so với MySQL/SQL Server, nếu đáng chú ý.
- Với Tier P/O: thêm phần "Đo bằng gì" (view hệ thống, EXPLAIN option, extension).

### Dataset
- Chọn DB theo bảng "Trục quy mô" trong ROADMAP: Tier F/I dùng `shop_s`, Tier P/R/O dùng `shop_m`, thí nghiệm dùng `shop_l`. `shop_xs` dùng khi người học cần nhìn toàn bộ dữ liệu để tự kiểm tra tay.
- Chỉ tạo schema riêng trong `lab` khi cần dữ liệu đặc thù, chẳng hạn bẫy NULL, cây, dữ liệu trùng. Nếu bài có phần quy mô, `setup.sql` nhận tham số N để sinh được nhiều mức.
- Seed phải **cố định** (`setseed()`) để kết quả kỳ vọng ổn định giữa các lần chạy.
- Đề bài ghi rõ chạy trên DB nào. Kết quả kỳ vọng tính theo DB đó.

### exercises.md
Khoảng 8–12 bài, chia 3 mức:
- 🟢 Cơ bản: áp dụng trực tiếp khái niệm.
- 🟡 Kết hợp: phối hợp với kiến thức các module trước.
- 🔴 Thực tế: đề viết bằng ngôn ngữ nghiệp vụ, kiểu "Marketing muốn biết…", có edge case ẩn.

Mỗi bài ghi: đề bài, cột output mong muốn, thứ tự sắp xếp, số dòng kỳ vọng. Có thể kèm 3 dòng đầu của kết quả.
Tier P trở đi có thêm dạng bài "tối ưu query này" (đưa sẵn query chậm), "dự đoán plan" và "giải thích vì sao".

**📏 Câu hỏi quy mô** (bắt buộc ≥1 bài từ Tier I, tùy chọn ở Tier F). Sau khi người học có lời giải đúng:
1. Hỏi người học dự đoán: "Ở `shop_l` (10M), query này mất khoảng bao lâu, plan có đổi không, có tràn đĩa không?" Ghi lời dự đoán vào `answers/exNN.sql` dưới dạng comment, **trước khi** chạy bench.
2. Chạy `bench/bench.sh answers/exNN.sql --scales s,m,l`.
3. So dự đoán với số đo. Chỉ ra điểm gãy (scale nào mà thời gian nhảy vọt hoặc plan đổi) và giải thích nguyên nhân.
4. Nếu lời giải sụp ở `l`: người học viết lại, hoặc đề xuất index rồi đo lại. Bài chỉ được tính ✅ đầy đủ khi đạt ở cả hai mặt: đúng và chịu được quy mô (theo quy tắc 7 trong CLAUDE.md).
5. Bảng kết quả bench được dán vào `review.md`.

### checks/ex<NN>.sql
Claude viết lời giải tham chiếu và cách so kết quả. **Không hiển thị nội dung file này cho người học.** Cách so kết quả:
```sql
-- số dòng khác nhau ở cả hai chiều phải bằng 0
(SELECT * FROM (<answer>) a EXCEPT ALL SELECT * FROM (<reference>) r)
UNION ALL
(SELECT * FROM (<reference>) r EXCEPT ALL SELECT * FROM (<answer>) a);
```
Đề có yêu cầu sắp xếp thì kiểm tra thêm thứ tự. Bài DML/DDL thì kiểm tra trạng thái bảng sau khi chạy, bọc trong transaction và `ROLLBACK`.

## 3. Vòng luyện tập
Với từng bài:
1. Người học viết vào `answers/exNN.sql` (hoặc dán vào chat; khi đó Claude lưu giúp vào file).
2. Chạy bài làm. Nếu lỗi cú pháp, chỉ chỉ ra vị trí lỗi, không sửa hộ.
3. So với check. Sai thì cho biết sai ở đâu: thiếu dòng, thừa dòng, sai giá trị hay sai thứ tự. Kèm 1 dòng ví dụ để người học tự tìm nguyên nhân.
4. Người học bí: dùng thang gợi ý H1 → H2 → H3 (xem CLAUDE.md), ghi lại số hint đã dùng.
5. Đúng: **bắt buộc** nhận xét và nêu best practice (xem "Nhận xét sau khi đúng" bên dưới). Lỗi nào là pattern lặp lại thì ghi vào weaknesses.

### Nhận xét sau khi đúng (bắt buộc, theo yêu cầu người học)
Mỗi bài người học làm đúng, đừng chỉ báo "✅ đúng". Luôn thêm phần nhận xét ngắn:
- **Làm đúng:** 2–3 điểm cụ thể (đúng vế đề nào, tránh được bẫy nào).
- **Best practice:** cách viết chuẩn/idiomatic nhất cho đề này. Nếu bài làm đã là best practice thì nói thẳng "đây đã là cách chuẩn" và vì sao. Nếu còn cách tốt hơn thì **luôn kèm code mẫu đầy đủ trong khối ```sql** (bài đã đúng nên được phép đưa query), không chỉ mô tả bằng lời. Code mẫu phải đã chạy thật và khớp kết quả của `checks`. Sau code, giải thích 2–3 lý do: ý định rõ ràng hơn, tránh bẫy (fan-out, NULL, múi giờ), dễ bảo trì.
  - Mô tả bằng lời mà không có code là **chưa đạt** yêu cầu này. Nếu có hai hướng (ví dụ cách gọn hơn nhưng không nhanh hơn, và cách sửa gốc cần index/khái niệm chưa học), đưa code cho cả hai, ghi rõ hướng nào cần kiến thức chưa học.
  - Kèm bảng so sánh ngắn (bản của bạn / bản mẫu): số dòng, thời gian, buffers khi liên quan.
- **Số đo khi liên quan hiệu năng:** chạy `EXPLAIN (ANALYZE, BUFFERS)` trên `shop_m` (từ Tier I thì thêm `shop_l`) cho cả hai bản, so thời gian và buffers. Ghi rõ nếu chỉ đo 1 lần hoặc cache lạnh nên con số chỉ mang tính xu hướng.
- **Trade-off:** nếu bản của người học dễ đọc hơn hoặc khác biệt không đáng kể ở quy mô hiện tại thì nói thẳng, không ép đổi.
- Giữ ngắn gọn, ưu tiên tối đa 3 điểm quan trọng nhất.

Không ra đề mới khi người học chưa nộp bài hiện tại, trừ khi người học muốn bỏ qua.

## 4. Kết thúc buổi
- Viết `review.md`: điểm (x/N), số hint, 3 điều nắm chắc, 3 điều cần cải thiện, các lỗi đã ghi vào weaknesses.
- Cập nhật `progress/tracker.md`:
  - Đổi trạng thái thành ✅ nếu đạt tiêu chí Pass trong ROADMAP, ngược lại giữ 🟡.
  - Ghi điểm, số hint, ngày, và "Ôn lại lúc" (theo lịch trong skill `sql`).
  - Thêm một entry vào Nhật ký buổi học.
- Đề xuất buổi sau trong 1 dòng.

## Riêng S00 (Setup)
Buổi này dựng hạ tầng, không có bài tập SQL:
1. `env/docker-compose.yml`: dùng `postgres:18`, container `sql-practice-pg`, port `5433:5432`, volume có tên. Command bật `shared_preload_libraries=pg_stat_statements`, đặt `shared_buffers=256MB` và `work_mem=4MB`. Hai giá trị nhỏ này là cố ý, để dữ liệu lớn vượt bộ nhớ đệm. Ghi chú cấu hình trong file.
2. `env/init/`: tạo DB `lab` và một DB template chứa sẵn extension (`pg_stat_statements`, `pg_trgm`, `unaccent`, `ltree`, `btree_gist`, `pg_buffercache`, `pg_prewarm`). Các DB `shop_*` được tạo từ template này.
3. `datasets/shop/`:
   - `schema.sql`: users, products, categories (dạng cây), orders, order_items, payments, events (jsonb). Chỉ có PK/FK, **chưa có index phụ**, để các bài sau tự thêm index.
   - `generate.sql`: sinh dữ liệu theo tham số `N` (`psql -v N=...`), seed cố định, tỉ lệ giữa các bảng cố định. Phân phối dữ liệu giống thực tế: có khách hàng "whale", sản phẩm hot (lệch kiểu Zipf), mùa vụ theo thời gian. Cố ý chèn một ít NULL, dữ liệu trùng và dữ liệu bẩn làm nguyên liệu cho các bài sau.
   - Dùng `INSERT … SELECT generate_series` hoặc `COPY`. Không dùng vòng lặp từng dòng (chính điều này sẽ được so sánh ở P10b).
   - `build.sh <scale>`: tạo `shop_<scale>` từ template, chạy schema, generate, rồi `ANALYZE`. In ra thời gian sinh và dung lượng DB.
   - `README.md`: ghi tỉ lệ các bảng, phân phối dữ liệu, và dung lượng thực đo được của từng mức.
4. Sinh `shop_xs`, `shop_s`, `shop_m`. **Chưa sinh `shop_l`**: hẹn sinh trước khi vào Tier P, sau khi đã kiểm tra dung lượng ổ đĩa và RAM cấp cho Docker Desktop. Ghi kết quả vào bảng "Dataset đã sinh" trong tracker.
5. `bench/bench.sh`: theo đặc tả trong CLAUDE.md. Thử với một query mẫu trên `xs,s,m`.
6. Hướng dẫn người học các lệnh psql: `\l \c \dt \d+ \x \timing \e \i`, và cách kết nối bằng GUI tùy chọn (DBeaver/pgAdmin).
7. Pass khi `bench` xuất được bảng so sánh của một query trên `xs,s,m`.

## Riêng P10 (Scale effects)
Đây là buổi thí nghiệm, không theo dạng đề bài thông thường. `exercises.md` là danh sách **thí nghiệm**. Mỗi thí nghiệm gồm 4 phần:

```
### Thí nghiệm N: <tên>
Giả thuyết (người học viết TRƯỚC khi chạy): ...
Cách đo: query / lệnh + bench --scales xs,s,m,l
Kết quả: bảng bench (+ biểu đồ ASCII nếu có ích)
Giải thích điểm gãy: ...
```

- **P10a · Đọc:**
  - Tìm điểm planner chuyển scan type bằng cách tăng dần selectivity.
  - Join algorithm đổi theo kích thước bảng.
  - Tăng/giảm `work_mem` để thấy sort/hash tràn ra đĩa (đọc `temp read/written` trong output).
  - Cache hit ratio trước/sau `pg_prewarm`, và trường hợp bảng vượt `shared_buffers`.
  - So sánh `COUNT(*)` chính xác với ước lượng từ `pg_class.reltuples`.
  - OFFSET sâu so với keyset.
  - Đo độ phức tạp thực tế: vẽ đường thời gian theo N, nhận dạng đường O(n) và O(log n).
- **P10b · Ghi & vận hành:**
  - Nạp 100k dòng bằng INSERT từng dòng (autocommit), INSERT theo batch, `COPY`.
  - Thời gian ghi khi bảng có 0, 1, 3 và 6 index.
  - `CREATE INDEX` so với `CONCURRENTLY` (thời gian và lock).
  - `ALTER TABLE ADD COLUMN` có default, `ALTER COLUMN TYPE`: đo thời gian rewrite, và lock quan sát từ session thứ hai.
  - `UPDATE` 30% bảng: đo bloat, rồi thời gian VACUUM.
  - Bảng dung lượng bảng/index/TOAST theo N.
- Cuối buổi viết `review.md` có mục **"Quy tắc ngón tay cái của tôi"**: 5–10 kết luận do người học tự rút ra từ số đo, vd. "ở máy này, seq scan 1M dòng mất khoảng X ms". Mục này dùng làm tham chiếu cho bước ước lượng trong sql-design.
