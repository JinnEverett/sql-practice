-- sai: không xử lý NULL → trang A dừng ở dòng cuối có ngày sinh, trang B trống
(SELECT 'A' AS case_no, id, birth_date FROM (
   SELECT id, birth_date FROM r02.members
   WHERE (birth_date, id) < ('1990-03-02', 6) ORDER BY birth_date DESC NULLS LAST, id LIMIT 8) a)
UNION ALL
(SELECT 'B', id, birth_date FROM (
   SELECT id, birth_date FROM r02.members
   WHERE (birth_date, id) > (NULL, 20) ORDER BY birth_date DESC NULLS LAST, id LIMIT 8) b)
ORDER BY case_no, birth_date DESC NULLS LAST, id;
