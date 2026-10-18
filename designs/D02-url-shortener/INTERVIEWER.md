# D02 · Interviewer (⚠️ spoiler)

## Thông tin chỉ đưa khi được hỏi
| Hỏi | Trả lời |
|---|---|
| Quy mô | 10M link mới/tháng; đọc:ghi = 100:1 (≈1 tỉ redirect/tháng); đỉnh gấp 10 trung bình |
| Latency | Redirect p99 < 50 ms ở server; tạo link < 300 ms |
| Code | 7 ký tự chữ-số, phân biệt hoa thường; không đoán được thứ tự |
| Hết hạn/xóa | Link có thể hết hạn; xóa là vô hiệu hóa ngay (≤ 1 phút chấp nhận được) |
| Custom alias | Có, cho khách trả phí |
| Analytics | Số click theo ngày, theo quốc gia, loại thiết bị; giữ chi tiết 90 ngày, tổng hợp giữ vĩnh viễn; chấp nhận số trễ vài phút và sai số nhỏ cho bot |

## Yêu cầu ngầm
1. **Không đụng độ code** dưới tải song song, không phải "random rồi hy vọng".
2. **Click ghi nhiều gấp 100 lần tạo link** → không cập nhật `links.click_count` mỗi click (hot row + bloat).
3. **Retention** click: xóa 90 ngày cũ không được bằng `DELETE` hàng tỉ dòng.
4. **Cache invalidation** khi link bị vô hiệu hóa/hết hạn.
5. Code công khai → **không lộ tuần tự** (đối thủ đếm số link/ngày).

## Câu hỏi phản biện
**B1** "Link bị xóa mà vẫn còn trong CDN/cache thì sao? Chấp nhận bao lâu?" · "Custom alias va chạm với code sinh tự động thế nào?"
**B2** "Redirect cần những cột nào? Có cần JOIN không?" · "Dashboard 30 ngày của 1 link đọc gì?"
**B3** "1 tỉ click/tháng = bao nhiêu QPS, bao nhiêu GB/tháng nếu mỗi click 100 byte? Giữ 90 ngày là bao nhiêu TB?" (≈ 385/s trung bình, ~4k/s đỉnh; ~100 GB/tháng, ~300 GB/90 ngày chưa kể index)
**B4** "Sinh code bằng gì: random, hash URL, hay sequence? Va chạm xử lý ra sao? Hash URL có vấn đề gì khi hai khách rút gọn cùng URL?" · "Click có FK về links không? Lý do?"
**B5** "Index nào phục vụ redirect? Nó chiếm bao nhiêu RAM với 120M link? Vừa shared_buffers không?"
**B6** "Cache đặt ở đâu, TTL bao nhiêu, hit-rate kỳ vọng? Khi cache chết hết cùng lúc (thundering herd) DB chịu nổi không?" · "Click đi thẳng INSERT hay qua queue/batch?"
**B7** "Link viral 50k click/giây: thứ gì nóng? Counter ở đâu?" · "Chia shard theo gì? `code` hay `owner_id`? Hậu quả với redirect?"

## Dấu hiệu đỏ
`UPDATE links SET clicks = clicks + 1` mỗi redirect · `DELETE FROM clicks WHERE ...` hàng tỉ dòng · `SELECT … WHERE long_url = ...` không index để chống trùng · random 6 ký tự không bàn xác suất va chạm.
