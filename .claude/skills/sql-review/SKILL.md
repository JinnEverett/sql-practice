---
name: sql-review
description: |
  Chấm và review câu SQL người học viết theo 6 trục: đúng đắn, edge case, khả năng đọc, hiệu năng, quy mô, an toàn. Chạy thật trên Postgres, dùng EXPLAIN khi cần, ghi lỗi lặp lại vào weaknesses.
  Triggers: /sql-review, "chấm bài", "review query này", "query này ổn không", "sao query tôi chậm", "query này chạy được với 10 triệu dòng không"
---

# SQL Review: chấm bài và code review

Input có thể là một file `.sql`, một thư mục `answers/`, hoặc query dán trong chat (kèm đề bài nếu có).
Mục tiêu: người học **hiểu vì sao**, không chỉ nhận một bản sửa.

## Quy trình

### 1. Xác định ngữ cảnh
- Query này giải quyết đề nào? Nếu thuộc một lesson/case thì đọc đề và file check tương ứng.
- Nếu là query tự do: hỏi ngắn gọn query cần làm gì và chạy trên DB nào.

### 2. Chạy và đo
```bash
echo "<query>" | MSYS_NO_PATHCONV=1 docker exec -i sql-practice-pg psql -U postgres -d <db> -X
```
- Query có trường hợp đúng/sai rõ ràng thì so với check hoặc lời giải tham chiếu (dùng EXCEPT ALL theo hai chiều).
- Từ Tier P trở đi, hoặc khi người học hỏi về hiệu năng: chạy `EXPLAIN (ANALYZE, BUFFERS)`. Query DML thì bọc trong `BEGIN … ROLLBACK`.
- Có nghi ngờ về khả năng chịu quy mô (từ Tier I trở đi): chạy `bench/bench.sh` trên `s,m,l` rồi dán bảng kết quả vào phản hồi.

### 3. Chấm theo 6 trục
| Trục | Câu hỏi kiểm tra |
|---|---|
| **Correctness** | Kết quả có đúng không? Có fan-out do JOIN không? GROUP BY đã đủ cột chưa? |
| **Edge cases** | Có NULL không? (`NOT IN`, `COUNT(col)`, so sánh `=`). Tập rỗng? Dữ liệu trùng? Ranh giới thời gian/time zone? Chia cho 0? Giá trị tie khi xếp hạng? |
| **Readability** | Alias rõ nghĩa chưa? CTE có đặt tên đúng ý nghĩa không? Format nhất quán chưa? Có chỗ lồng subquery không cần thiết không? |
| **Performance** | Điều kiện có sargable không? Đã có index phù hợp chưa? Có seq scan không cần thiết không? Hàm có đang bọc cột không? Có OFFSET lớn không? Kiểu dữ liệu có bị cast ngầm không? Ước lượng của planner có lệch không? |
| **Scale** | Query còn ổn ở 10M dòng không? Độ phức tạp là O(n), O(n log n) hay O(log n)? Có sort/hash tràn ra đĩa không? Có giữ lock lâu theo kích thước bảng không? Kiểm chứng bằng `bench --scales s,m,l` thay vì đoán |
| **Safety** | Có UPDATE/DELETE nào thiếu WHERE không? Có rủi ro race condition không? Lock có giữ quá lâu không? Có nguy cơ SQL injection nếu query được nhúng vào app không? |

Đánh giá mỗi trục là ✅ / ⚠️ / ❌, kèm 1 câu giải thích. Trục nào không áp dụng thì bỏ qua.

### 4. Phản hồi
Mẫu:
```
Kết quả: ❌ thiếu 3 dòng (khách hàng chưa có đơn nào)

Correctness ❌  INNER JOIN loại mất khách chưa có đơn, cần LEFT JOIN
Edge cases  ⚠️  COUNT(o.id) đúng, nhưng SUM(o.total) sẽ trả về NULL thay vì 0
Performance ✅  dùng Index Scan trên orders_customer_id_idx
Readability ⚠️  alias t1/t2 khó đọc, nên đặt c/o

👉 Thử sửa lại. Gợi ý: khách không có đơn thì giá trị SUM sẽ ra sao?
```
- Bài **sai**: KHÔNG đưa query đã sửa. Chỉ nêu vấn đề và đặt câu hỏi dẫn dắt.
- Bài **đúng**: **bắt buộc** nhận xét và nêu best practice, kể cả khi bài đã tốt. Gồm: điểm làm đúng; cách viết chuẩn nhất (nếu bài đã là best practice thì nói thẳng và vì sao; nếu còn cách tốt hơn thì **luôn kèm code mẫu đầy đủ trong khối ```sql**, đã chạy thật và khớp kết quả, rồi 2–3 lý do: ý định rõ hơn, tránh bẫy, dễ bảo trì; chỉ mô tả bằng lời mà không có code là chưa đạt); số đo so sánh (thời gian, buffers) khi liên quan đến hiệu năng, ghi rõ giới hạn nếu chỉ đo 1 lần; và trade-off nếu bản của người học dễ đọc hơn hoặc khác biệt không đáng kể.
- Có nhiều vấn đề: chỉ nêu tối đa 3 vấn đề quan trọng nhất mỗi lượt.

### 5. Ghi nhận
- Lỗi thuộc dạng pattern (vd. `null-not-in`, `join-fanout`, `non-sargable`, `offset-pagination`, `missing-where`, `tz-naive`, `rank-ties`): thêm dòng mới hoặc tăng `count` trong `progress/weaknesses.md`.
- Tag dùng kebab-case, ngắn gọn. Trước khi tạo tag mới, kiểm tra xem đã có tag tương tự chưa để tái sử dụng.
