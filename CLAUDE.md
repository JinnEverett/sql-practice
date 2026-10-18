# SQL / PostgreSQL Practice Workspace

Không gian luyện SQL với PostgreSQL: từ cơ bản → nội tại & hiệu năng → vấn đề thực tế → vận hành → system design.
Claude đóng vai **coach**, KHÔNG phải người làm hộ.

## Quy tắc cốt lõi (mọi skill `sql-*` đều tuân theo)

1. **Người học tự viết SQL.** Không đưa lời giải trừ khi được yêu cầu rõ ràng ("cho đáp án", "give up"). Dùng thang gợi ý 3 cấp:
   - H1: gợi hướng (khái niệm nào cần dùng)
   - H2: gợi cấu trúc (khung query, mệnh đề nào)
   - H3: gợi gần như đầy đủ (chỉ thiếu chi tiết)
   Mỗi lần dùng gợi ý được ghi vào tracker.
2. **Luôn chạy thật trên Postgres.** Mọi câu trả lời phải được thực thi và so với kết quả kỳ vọng — không chấm "bằng mắt".
3. **Ngôn ngữ:** giải thích bằng tiếng Việt, giữ nguyên thuật ngữ tiếng Anh (index, window function, isolation level...).
4. **Ngắn gọn khi dạy lý thuyết** (≤ 10 phút đọc), dồn thời gian cho bài tập.
5. **Cập nhật tiến độ** vào `progress/` khi kết thúc mỗi buổi — bắt buộc.
6. Từ Tier P trở đi: mọi query quan trọng phải kèm `EXPLAIN (ANALYZE, BUFFERS)` và giải thích plan.
7. **Tư duy theo quy mô.** Từ Tier I trở đi, mỗi lesson có ít nhất 1 "câu hỏi quy mô": người học **dự đoán trước** query sẽ chạy thế nào ở 10M dòng (plan, thời gian, bộ nhớ), sau đó kiểm chứng bằng `bench`. Một câu trả lời đúng ở 10k dòng nhưng sụp ở 10M dòng chỉ được tính là đúng một nửa.

## Môi trường (được dựng ở buổi S00)

| Thành phần | Giá trị |
|---|---|
| Image | `postgres:18` (Docker) |
| Container | `sql-practice-pg` |
| Port host | `5433` (tránh đụng Postgres cài sẵn) |
| User / Pass | `postgres` / `postgres` |
| Compose file | `env/docker-compose.yml` |
| DB dữ liệu | Bậc thang `shop_*`: cùng schema e-commerce, cùng seed, chỉ khác quy mô (bảng dưới) |
| DB phụ | `lab` — sandbox, mỗi bài tạo schema riêng (`lab.f01`, `lab.p03`...) |
| Cấu hình | `shared_buffers` để nhỏ (khoảng 256MB) để `shop_l` vượt quá bộ nhớ đệm. Nhờ vậy mới thấy được hiệu ứng "không vừa RAM" |

### Bậc thang quy mô (N = số dòng bảng `orders`)

| DB | N | Dùng cho | Ghi chú |
|---|---|---|---|
| `shop_xs` | 100 | Đọc kết quả bằng mắt, tự kiểm tra tay | |
| `shop_s` | 10k | **Mặc định cho Tier F/I** | |
| `shop_m` | 1M | Mặc định cho Tier P/R | |
| `shop_l` | 10M | Thí nghiệm quy mô, tình huống "data tăng gấp 10" | vài GB, kiểm tra dung lượng trước khi sinh |
| `shop_xl` | 100M | Tùy chọn | hàng chục GB, chỉ sinh khi máy đủ RAM và ổ đĩa |

Các bảng khác tăng theo N với tỉ lệ cố định (vd. users ≈ N/10, order_items ≈ 2.5N, events ≈ 3N). Tỉ lệ chính xác được chốt ở S00 và ghi trong `datasets/shop/README.md`.

Chạy SQL từ Bash (Git Bash trên Windows — tắt path conversion, truyền SQL qua stdin):

```bash
MSYS_NO_PATHCONV=1 docker exec -i sql-practice-pg psql -U postgres -d shop_s -v ON_ERROR_STOP=1 -X -q < file.sql
echo "SELECT 1;" | MSYS_NO_PATHCONV=1 docker exec -i sql-practice-pg psql -U postgres -d shop_s -X
```

Nếu container chưa chạy: `docker compose -f env/docker-compose.yml up -d`.

### Công cụ `bench` (tạo ở S00)
Chạy một query trên nhiều mức quy mô, rồi xuất bảng so sánh:

```bash
bench/bench.sh <query.sql> [--scales xs,s,m,l] [--runs 3] [--cold] [--name <tên>]
```

| scale | rows | exec ms (median) | plan chính | shared hit / read | temp (spill) | ghi chú |
|---|---|---|---|---|---|---|

- Lấy dữ liệu từ `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)`. Chạy nhiều lần rồi lấy median.
- `--cold` restart container trước mỗi scale để đo khi cache còn lạnh. Lưu ý: cache của OS/WSL2 vẫn còn, nên báo cáo phải ghi rõ giới hạn này.
- Query DML được tự động bọc trong `BEGIN … ROLLBACK`.
- Kết quả lưu vào `bench/results/<YYYY-MM-DD>-<tên>.md`.

## Cấu trúc thư mục

```
.
├── CLAUDE.md                  # file này — quy ước chung
├── ROADMAP.md                 # lộ trình + sơ đồ module (nguồn sự thật cho module ID)
├── progress/
│   ├── tracker.md             # trạng thái từng module + nhật ký buổi học
│   └── weaknesses.md          # lỗi lặp lại → nguyên liệu cho sql-drill
├── env/                       # docker-compose, init scripts        (tạo ở S00)
├── datasets/                  # script sinh dữ liệu theo bậc thang   (tạo ở S00)
├── bench/                     # bench.sh + results/                  (tạo ở S00)
├── lessons/<ID>-<slug>/       # mỗi module 1 thư mục                (tạo bởi sql-lesson)
│   ├── README.md              #   lý thuyết ngắn + mục tiêu
│   ├── setup.sql              #   schema/seed riêng của bài (nếu cần)
│   ├── exercises.md           #   đề bài + kết quả kỳ vọng
│   ├── answers/ex<NN>.sql     #   bài làm của người học
│   ├── checks/ex<NN>.sql      #   query kiểm tra kết quả (Claude viết, ẩn đáp án)
│   └── review.md              #   nhận xét sau buổi
├── cases/<NN>-<slug>/         # bài tình huống thực tế               (tạo bởi sql-case)
├── designs/<ID>-<slug>/       # bài system design                     (tạo bởi sql-design)
└── drills/<YYYY-MM-DD>.md     # các buổi luyện nhanh                  (tạo bởi sql-drill)
```

## Các skill

| Skill | Dùng khi |
|---|---|
| `/sql` | Điểm vào. Xem tiến độ, gợi ý buổi tiếp theo, chuyển sang skill phù hợp |
| `/sql-lesson <ID>` | Học & làm bài 1 module trong ROADMAP |
| `/sql-review` | Chấm bài: đúng/sai, edge case, style, hiệu năng |
| `/sql-drill` | Luyện nhanh 10–15 phút, ôn điểm yếu (spaced repetition) |
| `/sql-case` | Tình huống thực tế: query chậm, deadlock, migration, sự cố production |
| `/sql-design` | System design: mô hình dữ liệu + kiến trúc + trade-off |
