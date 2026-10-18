# D04 · Interviewer (⚠️ spoiler)

## Thông tin chỉ đưa khi được hỏi
| Hỏi | Trả lời |
|---|---|
| Quy mô | 5M khách, 2M chuyển tiền/ngày (≈ 23/s TB, đỉnh ~500/s lúc lương/sale); mỗi chuyển tiền = 2 entries |
| Tiền tệ | Chỉ VND giai đoạn 1; thiết kế phải mở được cho USD (không float; đơn vị nhỏ nhất) |
| Thấu chi | Khách không được âm. Tài khoản hệ thống (nguồn nạp, phí) được âm |
| Số dư | Hiển thị realtime, p99 < 50 ms; sao kê 100 giao dịch/trang |
| Sửa lỗi | Không bao giờ sửa/xóa dòng lịch sử; sai thì hoàn |
| Đối soát | Hằng ngày với sao kê ngân hàng đối tác; phải chỉ ra lệch/thiếu/thừa |
| Audit | Giữ 10 năm, truy vấn nóng 13 tháng |

## Yêu cầu ngầm
1. **Mỗi giao dịch cân bằng** (tổng = 0) và DB phải tự bảo vệ, không tin app.
2. **Idempotency**: client/gateway retry; cùng key khác nội dung phải bị từ chối chứ không "thắng cuộc".
3. **Deadlock** khi A→B đồng thời B→A.
4. **Append-only**: không UPDATE/DELETE sổ cái; hoàn tiền = giao dịch bù trừ, chỉ hoàn 1 lần.
5. **Số dư lưu hay tính**: tính từ 1 tỉ entries thì không khả thi; lưu thì phải chứng minh luôn khớp (job đối soát nội bộ).
6. **Hot account**: tài khoản phí/nguồn tiền dính mọi giao dịch.
7. **Làm tròn/tiền float**, đơn vị.

## Câu hỏi phản biện
**B1** "Thấu chi: chặn ở app hay DB? Hai lệnh rút đồng thời cùng chạm số dư cuối?" · "Hoàn tiền nghĩa là xóa giao dịch cũ?"
**B2** "Liệt kê access pattern: số dư, sao kê, số dư tại ngày T, đối soát, báo cáo cuối ngày. Cái nào không được đụng bảng nóng?"
**B3** "4M entries/ngày × 365 = ? dòng/năm; × bytes/dòng = ? GB/năm. 10 năm?" (≈ 1.46 tỉ/năm; ~190 B/entry ⇒ ~280 GB/năm). "500 chuyển/s đỉnh ở Postgres đơn lẻ có ổn không, và bottleneck đầu tiên là gì?"
**B4** "`amount` kiểu gì? Dấu âm/dương hay hai cột debit/credit? Vì sao?" · "Ràng buộc 'tổng entries = 0' thể hiện bằng gì? CHECK làm được không?" (CHECK chỉ nhìn một dòng ⇒ constraint trigger deferred)
**B5** "Sao kê phân trang 1 tỉ dòng: OFFSET có chịu nổi không? Index gì?" · "Số dư tại ngày T lấy thế nào mà không cộng dồn?" (balance_after)
**B6** "Số dư cập nhật trong cùng transaction với entries hay bất đồng bộ? Mất gì?" · "Phân vùng entries thế nào, retention 10 năm ra sao?"
**B7** "Tài khoản phí tham gia mọi giao dịch: hot row xử lý ra sao (tách phí sang bảng/chunk, ghi gộp)?" · "Lệch giữa `balances` và `sum(entries)`: phát hiện, sửa, và điều tra nguyên nhân thế nào?"

## Dấu hiệu đỏ
`float` cho tiền · `UPDATE balance` không có entries tương ứng · sửa/xóa entries · idempotency chỉ bằng check-then-insert · khóa tài khoản không có thứ tự · `OFFSET` cho sao kê.
