-- db: lab
-- reset
-- ordered
-- expect-rows: 16
-- Giải thích: ORDER BY birth_date DESC NULLS LAST, id: NULL nằm CUỐI. So sánh row-value với NULL cho kết quả NULL (không true/false) nên không dùng được.
--   Phải viết tường minh hai trường hợp:
--   • cursor có birth_date (A): các dòng sau nó là { birth_date nhỏ hơn, hoặc bằng nhưng id lớn hơn, hoặc birth_date IS NULL } (NULL đứng sau mọi giá trị)
--   • cursor là NULL (B): chỉ còn các dòng NULL có id lớn hơn.
-- Bẫy: (birth_date, id) > (…) với cursor NULL trả 0 dòng; quên nhánh "OR birth_date IS NULL" ở A làm trang cuối dừng sớm, mất 15 người NULL.
(SELECT 'A' AS case_no, id, birth_date
 FROM (
   SELECT id, birth_date FROM r02.members
   WHERE birth_date < '1990-03-02'
      OR (birth_date = '1990-03-02' AND id > 6)
      OR birth_date IS NULL
   ORDER BY birth_date DESC NULLS LAST, id
   LIMIT 8) a)
UNION ALL
(SELECT 'B', id, birth_date
 FROM (
   SELECT id, birth_date FROM r02.members
   WHERE birth_date IS NULL AND id > 20
   ORDER BY birth_date DESC NULLS LAST, id
   LIMIT 8) b)
ORDER BY case_no, birth_date DESC NULLS LAST, id;
