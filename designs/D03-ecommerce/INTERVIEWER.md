# D03 · Interviewer (⚠️ spoiler)

## Thông tin chỉ đưa khi được hỏi
| Hỏi | Trả lời |
|---|---|
| Quy mô | 50k đơn/ngày thường; flash sale: 5k đơn trong 60 giây trên ~20 sản phẩm, 1 sản phẩm hot có 500 tồn |
| Giữ chỗ | Giữ lúc đặt, hết hạn sau 15 phút nếu chưa thanh toán |
| Thanh toán | Cổng bên ngoài gọi webhook; có thể gửi lại nhiều lần, có thể đến trễ hoặc sai thứ tự |
| Kho | 1 kho; trừ kho thật khi thanh toán xong |
| Hủy/hoàn | Hủy trước khi giao; hoàn tiền sau khi giao trong 7 ngày |
| Giá | Giá có thể đổi giữa lúc xem và lúc đặt; hóa đơn phải giữ giá lúc mua |
| Retention | Đơn giữ 10 năm (kế toán) |

## Yêu cầu ngầm
1. **Oversell**: 5k request tranh 500 hàng; mọi check-then-act ở app đều sai.
2. **Idempotency** đặt đơn (double-click, mạng chập chờn) và webhook (gửi lại).
3. **State machine** hợp lệ ở tầng DB (ai đó viết service mới không được phá).
4. **Deadlock** khi đơn nhiều dòng khóa tồn kho theo thứ tự khác nhau.
5. **Snapshot giá** trong `order_items`.
6. **Hot row** tồn kho sản phẩm hot; **bloat** của bảng bị UPDATE nhiều.
7. **Đối soát**: reserved ↔ đơn pending; payments ↔ cổng.

## Câu hỏi phản biện
**B1** "Giữ chỗ lúc đặt hay lúc thanh toán? Mỗi lựa chọn hỏng ở đâu (giữ chỗ → bị chiếm hàng ảo; không giữ → khách trả tiền xong hết hàng)?"
**B2** "Liệt kê query của luồng checkout. Query nào chạm cùng một dòng nhiều nhất?"
**B3** "5k đơn/60 giây = bao nhiêu TPS? Mỗi đơn chạm bao nhiêu dòng? Hot row xử lý tuần tự thì tối đa bao nhiêu update/s trên 1 dòng?" (≈ 83 đơn/s; mỗi đơn ~3–6 dòng ghi; hot row cỡ vài trăm–nghìn update/s tùy độ dài transaction — nêu là ước lượng)
**B4** "Tồn kho đặt ở `products` hay bảng riêng? Vì sao? Có CHECK không?" · "Trạng thái đơn lưu là text, enum hay bảng tham chiếu? Làm sao cấm `delivered → pending`?" · "Tiền kiểu gì (float?)"
**B5** "Hai request cùng trừ 1 hàng cuối: chuyện gì xảy ra ở isolation Read Committed? Viết câu UPDATE." · "Job quét đơn hết hạn chạy ra sao khi `orders` có 50M dòng? Index gì?"
**B6** "Webhook đến 2 lần cùng lúc thì sao?" · "Có dùng queue cho đặt đơn trong flash sale không? Được/mất gì?" · "Cổng báo thành công nhưng đơn đã hết hạn và hủy: xử lý thế nào?"
**B7** "Sản phẩm hot nhận 2k request/s vào cùng 1 dòng: cách giảm contention (chia nhỏ kho thành bucket, xếp hàng, token giữ chỗ trước ở Redis)?" · "Dung lượng `orders` sau 10 năm? Partition thế nào mà vẫn tra theo `user_id`?"

## Dấu hiệu đỏ
`SELECT stock` rồi `UPDATE stock = stock - n` hai bước · float cho tiền · không khóa thứ tự · webhook không idempotent · status là text tự do không ràng buộc · FK `ON DELETE CASCADE` từ users xuống orders.
