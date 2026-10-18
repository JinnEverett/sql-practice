# Brief cho agent soạn bài (chạy trên cloud)

Bạn đang soạn **nội dung khóa học SQL/PostgreSQL** trong repo này (workspace luyện tập bằng tiếng Việt). Mỗi agent nhận **một nhóm module** và làm trên **một branch riêng**. Người học đang ở F08, nên các module bạn soạn sẽ được học sau; chúng phải đúng ngay lần đầu.

## Đọc trước (bắt buộc, theo thứ tự)
1. `CLAUDE.md` — quy tắc coach/người học, bậc thang quy mô `shop_*`, tư duy theo quy mô.
2. `ROADMAP.md` — mục "Danh mục module": nội dung chính + tiêu chí **Pass** của từng module bạn được giao; mục "Trục quy mô".
3. `tools/AUTHORING.md` — thư mục bài, file, header của `solutions/exNN.sql`, các mode `query|state|check|manual`, hàm test trong `tools/lib.sql`.
4. `.claude/skills/sql-lesson/SKILL.md` (Tier F–R–O) hoặc `.claude/skills/sql-design/SKILL.md` (Tier D) — yêu cầu về README, đề, hint, câu hỏi quy mô.
5. Bài mẫu hoàn chỉnh để bắt chước văn phong và độ sâu: `lessons/I07-jsonb-arrays/` hoặc `lessons/I04-window-frames/` (README, `setup.sql`, `exercises.md`, `hints.md`, `solutions/` có `.trapK.sql`/`.altK.sql`). **Đừng** lấy F01–F07 làm mẫu: đó là định dạng cũ (`checks/`, không có `solutions/`).
6. `datasets/shop/README.md` + `schema.sql` — schema và tỉ lệ dữ liệu của `shop_*`.

## Mỗi module bạn soạn phải có
```
lessons/<ID>-<slug>/
  README.md            # tiếng Việt, giữ thuật ngữ tiếng Anh, ≤ 10' đọc; ví dụ chạy được; bẫy; phần "Đo bằng gì" (Tier P/O)
  setup.sql            # nếu cần: schema lab.<id> + seed cố định, idempotent (DROP SCHEMA IF EXISTS … CASCADE)
  exercises.md         # 6–10 bài 🟢🟡🔴; ghi rõ db, cột, thứ tự, **N dòng**, dòng đầu; 📏 câu hỏi quy mô từ Tier I
  hints.md             # H1/H2/H3 mỗi bài, trong <details>
  solutions/exNN.sql   # đáp án + header chấm + `-- Giải thích:` / `-- Bẫy:`
  solutions/exNN.trapK.sql   # lời giải SAI hay gặp (verify.sh yêu cầu bị chấm SAI)
  solutions/exNN.check.sql / .state.sql / .md   # tùy mode
  answers/.gitkeep
```
Slug: chữ thường, gạch ngang, bám tên chủ đề trong ROADMAP (vd. `P02-btree-index`).
Tier D: `designs/<ID>-<slug>/` với `BRIEF.md` (đề 2–3 câu, cố ý mơ hồ), `INTERVIEWER.md` (spoiler: ngân hàng câu hỏi phản biện theo 7 bước + yêu cầu ngầm), `REFERENCE.md` (spoiler: thiết kế tham chiếu 7 bước, mermaid, số ước lượng, trade-off), `RUBRIC.md`, `schema.sql` (+ `queries.sql` chạy được).

## Quy tắc chất lượng
- **Chấm bằng máy, công bằng.** Bài kiểm kết quả/plan/trạng thái, không kiểm chuỗi SQL. Tier P dùng `plan()`, `has_node()`, `uses_index()`, `buffers()`, `temp_written()` với **ngưỡng rộng** (không so thời gian tuyệt đối; thứ tự/khoảng so sánh ≥ 2×) để không flaky.
- Mỗi module có ít nhất một bài **bẫy** thật (NULL, múi giờ, implicit cast, phantom, lost update, plan lệch do stats…) và bài 🔴 viết bằng ngôn ngữ nghiệp vụ ("Team báo…").
- Từ Tier I: ≥ 1 bài **📏 câu hỏi quy mô** (dự đoán rồi chạy `bench/bench.sh`; check chỉ kiểm cấu trúc của câu trả lời, không kiểm con số). Tier P/R: mọi query quan trọng kèm `EXPLAIN (ANALYZE, BUFFERS)` và lời giải thích plan.
- Bài cần **2 session** (P06 anomaly, P08 lock/deadlock, R04, R08): mô phỏng bằng 2 kết nối trong `check.sql` (`env/init` không cài dblink/`pg_background`; dùng `psql` chạy nền hoặc `pg_sleep` + `lock_timeout`, hoặc mô tả trình tự `manual` kèm kết quả thật). Ghi rõ cách chạy trong `exercises.md`.
- Bài cần quyền superuser/cấu hình server (O02–O06, P07, P10): dùng `mode: manual` + lời giải `.md` kèm **số đo thật** bạn đã chạy; không bịa số.
- **Phiên bản.** Workspace dùng Postgres 18. Cloud có thể chỉ có 16/17. Tính năng mới của 18 (async I/O, B-tree skip scan, `uuidv7()`, virtual generated columns, `OLD/NEW` trong `RETURNING`…) nếu bạn không chạy được thì **ghi rõ "chưa verify trên 18"** trong báo cáo, không dạy sai. Đối chiếu tài liệu chính thức khi không chắc.
- Không dạy API/tính năng đã deprecated. Không gọi dịch vụ ngoài internet trong check.
- Văn phong: ngắn gọn, số liệu cụ thể, không khen chung chung; tiếng Việt, giữ thuật ngữ tiếng Anh.

## KHÔNG đụng vào
- `progress/` (tracker, weaknesses), `drills/`, `lessons/*/answers/` có nội dung, và các module **F01–F10, I01–I07** (đã học/đã soạn xong). Chỉ nhóm O được sửa `I08`.
- Module ngoài nhóm của bạn. Ngoại lệ: `tools/` (xem dưới), `tools/CONTENT_PLAN.md` (dòng của nhóm bạn) và `datasets/shop/README.md` (chỉ **thêm** ghi chú, không đổi tỉ lệ dữ liệu đã chốt).
- Cần đổi `tools/lib.sql` / `check.sh` / `verify.sh`: chỉ **thêm** hàm/tùy chọn mới, không đổi chữ ký cũ; nêu rõ trong báo cáo. Nhiều agent cùng sửa các file này sẽ conflict, nên thêm vào cuối file, kèm comment tên nhóm.

## Môi trường verify (cloud VM Ubuntu 24.04: có Docker và PostgreSQL 16 cài sẵn)
Scripts đọc `SQL_PG` (xem `tools/pg-runner.sh`): `docker` (mặc định, container `sql-practice-pg`) hoặc `local` (psql trực tiếp).

**Cách ưu tiên: Postgres 18 qua Docker (đúng phiên bản của người học; Docker Hub nằm trong danh sách Trusted).**
```bash
docker compose -f env/docker-compose.yml up -d     # container sql-practice-pg, init tạo lab + shop_template
until docker exec sql-practice-pg pg_isready -U postgres -q; do sleep 1; done
bash datasets/shop/build.sh xs && bash datasets/shop/build.sh s
bash datasets/shop/build.sh m                      # 1M orders, ~900MB, vài phút: chỉ nhóm P/R/D cần
bash tools/verify.sh lessons/<ID>-*                # mọi đáp án tự khớp, mọi trap bị bắt, số dòng đúng
```
**Dự phòng: PostgreSQL 16 cài sẵn** (không có tính năng riêng của 18; ghi "chưa verify trên 18" nếu bài dùng chúng):
```bash
service postgresql start
export SQL_PG=local PGHOST=localhost PGPORT=5432 PGUSER=postgres PGPASSWORD=postgres   # đặt mật khẩu: sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres'"
psql -f env/init/01-init.sql                       # cần extension contrib (postgresql-contrib)
```
KHÔNG sinh `shop_l` (10M, ~9GB): bài cần shop_l thì ghi "chưa verify trên shop_l" trong báo cáo.
Lệnh foreground mặc định chờ 2 phút (tối đa 10 phút): chạy `build.sh m` và `verify.sh` dài ở nền (`nohup … &`) rồi đọc log.
Bài P cần "không vừa RAM": đặt `shared_buffers`/`work_mem` nhỏ trong `setup`/bằng `SET` cục bộ trong bài, và ghi giới hạn của phép đo (cloud ≠ máy người học) trong `README`.
Nếu không dựng được Postgres: vẫn soạn đầy đủ nhưng ghi **mọi** module là "chưa verify" trong báo cáo.

## Git
- Branch của bạn: `content/<nhóm>` (nhóm: `p`, `r`, `o`, `d`). Commit nhỏ theo module: `feat(P02): b-tree index`. Push thường xuyên.
- **Không** sửa `ROADMAP.md` (nếu thấy cần đổi thứ tự/nội dung module, nêu trong báo cáo).
- Cuối cùng cập nhật `tools/CONTENT_PLAN.md` (dòng của nhóm: ✅ hoặc 🧪 nếu `verify.sh` xanh) và viết `tools/reports/<nhóm>.md`: danh sách module, bài nào đã verify, bài nào chưa, số đo thật đã dùng, quyết định thiết kế đáng chú ý, thay đổi ở `tools/`.

## Bảng phân công
| Branch | Module |
|---|---|
| `content/p` | P01–P10 (P10 gồm P10a, P10b). Mặc định `shop_m`; thí nghiệm quy mô trên `shop_l` đánh dấu chưa verify nếu không chạy được |
| `content/r` | R01–R12 |
| `content/o` | **I08** (thiếu README/exercises/hints), I09, O01–O06 |
| `content/d` | D01–D10 (thư mục `designs/`) |
