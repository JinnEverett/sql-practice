# D05 · Interviewer (⚠️ spoiler)

## Thông tin chỉ đưa khi được hỏi
| Hỏi | Trả lời |
|---|---|
| Tài nguyên | 20k phòng/phòng họp/bác sĩ (đặt theo khung thời gian tùy ý, bội số 30 phút) **và** sự kiện có ghế cố định (500 ghế/sự kiện) |
| Quy mô | 100k booking/ngày; đợt mở bán sự kiện: 20k người tranh 500 ghế trong 1 phút |
| Giữ chỗ | 10 phút cho phòng, 5 phút cho ghế; quá hạn thì nhả |
| Hủy | Hủy được, nhả chỗ ngay |
| Múi giờ | Đa múi giờ: mỗi tài nguyên có `tz`; "đêm 14/03" tính theo giờ địa phương của tài nguyên |
| Đặt liền kề | 10:00–12:00 và 12:00–14:00 cùng phòng là hợp lệ |
| Lịch sử | Giữ vĩnh viễn; truy vấn nóng 90 ngày |

## Yêu cầu ngầm
1. **Double booking** chỉ chặn được bằng thứ DB phân xử (EXCLUDE / UPDATE có điều kiện), không bằng check-then-insert.
2. **Hold hết hạn**: constraint không biết `now()` ⇒ hold quá hạn vẫn "chiếm chỗ" cho tới khi bị dọn.
3. **Khoảng nửa mở `[)`** để liền kề không bị coi là chồng.
4. **Múi giờ/DST**: lưu `timestamptz`, tính ranh giới ngày bằng tz của tài nguyên.
5. **Sweeper song song** không giẫm nhau (`SKIP LOCKED`).
6. **Cast kiểu**: operator class của GiST khớp kiểu cột (bẫy int4 vs bigint).
7. **Thundering herd** khi mở bán: 20k người cùng ghế/ghế hot.

## Câu hỏi phản biện
**B1** "Hold quá hạn mà user vẫn bấm 'Thanh toán' thì sao? Cổng thanh toán báo thành công sau khi hold hết hạn và đã bán cho người khác?" · "Đổi lịch = hủy + đặt lại hay sửa tại chỗ?"
**B2** "Query tìm tài nguyên trống trong khung giờ X: viết thế nào? Query nào nóng nhất lúc mở bán?"
**B3** "100k/ngày ≈ ? QPS. 20k người trong 60 giây ≈ ? Mỗi ghế nhận bao nhiêu request?" (≈ 1.2 booking/s TB; mở bán ≈ 333 hold/s đổ vào 500 ghế)
**B4** "Chặn chồng thời gian bằng gì? CHECK làm được không? UNIQUE (resource, start) đủ không?" (không: [10,12) và [11,13) khác start) · "Biểu diễn khoảng bằng 2 cột hay `tstzrange`? Đóng/mở đầu cuối thế nào?"
**B5** "EXCLUDE cần extension gì? Index nào được tạo? Bao nhiêu dung lượng? Truy vấn kiểm tra chỗ trống dùng nó ra sao?"
**B6** "Ai dọn hold quá hạn: job, trigger, hay 'hết hạn lười' lúc có người tranh? Cả ba cùng chạy thì sao?"
**B7** "50 request cùng lúc vào một khung giờ: kết quả? Có deadlock không? Retry thế nào?" · "Ghế hot lúc mở bán: giảm tải bằng hàng chờ phòng chờ (virtual waiting room)?" · "Partition `bookings` theo gì khi EXCLUDE phải chứa khóa phân vùng?"

## Dấu hiệu đỏ
`SELECT … WHERE NOT EXISTS` rồi `INSERT` · hết hạn chỉ dựa vào job (hold quá hạn chặn người sau) · lưu giờ local không tz · `[]` đóng hai đầu · UNIQUE (resource, start_time) tưởng là đủ · không retry khi bị chọn làm nạn nhân deadlock.
