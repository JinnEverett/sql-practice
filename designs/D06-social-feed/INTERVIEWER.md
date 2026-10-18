# D06 · Interviewer (⚠️ spoiler)

## Thông tin chỉ đưa khi được hỏi
| Hỏi | Trả lời |
|---|---|
| Quy mô | 20M user, 5M DAU, 5M bài/ngày (~58/s TB, ~600/s đỉnh), đọc feed ~50 lần/user/ngày (≈ 2.9k/s TB) |
| Đồ thị | Trung bình 150 follower/tác giả; top 0.01% có > 1M follower; một số power user follow > 2000 người |
| Feed | Mới nhất trước (chưa xếp hạng ML), 20 bài/trang, cuộn vô hạn |
| Độ tươi | Bài mới xuất hiện trong feed follower trong ≤ 30 giây |
| Unfollow/xóa | Unfollow: bài của họ biến mất khỏi feed trong ≤ vài phút. Xóa bài: biến mất khỏi mọi feed |
| Like | Hiển thị số like xấp xỉ được (±1%), nhưng không được cho một người like hai lần |
| Retention | Feed chỉ cần giữ 7 ngày gần nhất; bài giữ vĩnh viễn |

## Yêu cầu ngầm
1. **Write amplification** của fan-out on write: 1 bài của người có 1M follower = 1M dòng. Phải có ngưỡng celebrity.
2. **Chi phí đọc pull** tăng theo số người mình follow (power user).
3. **Celebrity + hybrid**: đọc = hộp thư (push) ∪ bài mới của celebrity (pull).
4. **Counter nóng**: một bài viral nhận hàng nghìn like/giây vào một dòng.
5. **Keyset pagination** (không OFFSET); cursor ổn định khi có bài mới.
6. **Unfollow / xóa bài** với bảng hộp thư: lọc lúc đọc hay dọn nền.
7. **Idempotency like**; counter lệch phải đối soát được.

## Câu hỏi phản biện
**B1** "Feed xếp theo thời gian thuần hay xếp hạng? Điều đó đổi gì về thiết kế?" · "Bài của người mình mới follow có hiện không?"
**B2** "Hai access pattern chính của feed là gì? Tách read path và write path."
**B3** "5M bài × 150 follower = ? dòng hộp thư/ngày, × bytes/dòng = ? GB/ngày. Giữ 7 ngày thì sao? Với 1 celebrity 5M follower đăng 10 bài/ngày?" (≈ 750M dòng/ngày ≈ 64 GB/ngày ở ~85 B/dòng; celebrity: 50M dòng/ngày)
**B4** "`follows` có PK gì, index theo chiều nào để trả lời cả 'ai follow tôi' lẫn 'tôi follow ai'?" · "Hộp thư có FK về posts không? Vì sao không?"
**B5** "Viết query feed bằng pull. Với người follow 2000 tài khoản nó chạy thế nào (đọc plan)?" · "Viết query push. Cursor là gì?"
**B6** "Ngưỡng celebrity là bao nhiêu và ai quyết? Tác giả vượt ngưỡng giữa chừng thì hộp thư cũ thế nào?" · "Fan-out làm đồng bộ trong request đăng bài hay bằng queue/worker?"
**B7** "Bài viral 20k like/s: hot row ở đâu và cách giải? Đọc số like có đắt không?" · "Shard `feed_items` theo gì? (user_id)" · "x10 người dùng thì gì vỡ trước: ghi hộp thư hay đọc pull?"

## Dấu hiệu đỏ
`OFFSET` để phân trang feed · fan-out đồng bộ cho 1M follower trong request · không có ngưỡng celebrity · `UPDATE posts SET likes = likes + 1` ở mọi like · `COUNT(*)` bảng likes mỗi lần hiển thị · không bàn unfollow.
