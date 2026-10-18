select id, qty, unit_price_vnd, qty::numeric * unit_price_vnd as line_total
from f02.b2b_lines
order by qty::numeric*unit_price_vnd desc, id asc;
-- Câu hỏi phụ: "vì nó nhân ra kết quả sai rồi mới ép kiểu" ✅ (ý đúng; chính xác hơn: phép nhân integer báo lỗi out of range, không ra kết quả sai)
