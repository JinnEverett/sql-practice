# D04 · Rubric (tối đa 30, ✅ khi ≥ 22)

| Tiêu chí | 1–2 | 3–4 | 5 |
|---|---|---|---|
| Làm rõ requirements | Chỉ "chuyển tiền" | Có thấu chi + hoàn tiền | + đối soát, audit/retention, quy mô số, đơn vị tiền, tài khoản hệ thống |
| Data model | Một bảng `transfers(from,to,amount)` + cột balance | Double-entry có `entries` | Entries có dấu, append-only (trigger/quyền), tổng giao dịch = 0 ép bằng constraint trigger deferred, balance CHECK, `balance_after`, bigint không float |
| Index & query | Sao kê dùng OFFSET | Index `(account_id, created_at)` | Keyset pagination, số dư tại T = 1 index scan, đọc plan |
| Consistency & concurrency | Check-then-update | Transaction + `FOR UPDATE` | Khóa có thứ tự, idempotency (key + hash nội dung), hoàn 1 lần bằng unique index; **có thí nghiệm** với số đo deadlock/invariant |
| Scale & vận hành | Không ước lượng | Có dòng/năm, không partition | Dòng/năm + GB/năm; partition theo tháng + archive; hot account; đối soát nội bộ & với đối tác |
| Trade-off | Một cách tính số dư | So sánh 2 | So sánh tính-khi-đọc / lưu balance / balance bất đồng bộ + sổ cái snapshot; nêu khi nào đổi lựa chọn |

**Trừ nặng:** float cho tiền hoặc cho phép UPDATE/DELETE entries (−3 Data model). Không có thí nghiệm (−2 Consistency).
Review: 3 mạnh + 3 lỗ hổng. Hệ thống thật: sổ cái bất biến + giao dịch bù trừ (kiểu Stripe/Square/Modern Treasury), số dư là bản chiếu có kiểm tra, hot account xử lý bằng sub-ledger/ghi gộp.
