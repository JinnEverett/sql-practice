-- db: shop_s
-- ordered
-- Giải thích: age(ngày_mốc, birth_date) trả interval "x years y mons z days"; extract(year …) lấy số tuổi tròn,
--   đã tính đúng việc qua sinh nhật hay chưa. Nhóm NULL đặt nhãn riêng và xếp cuối (min(tuổi) NULL → NULLS LAST mặc định khi ASC).
-- Bẫy: 2026 - extract(year from birth_date) dư 1 tuổi với người chưa tới sinh nhật trong năm; quên lọc deleted_at.
SELECT CASE
         WHEN age IS NULL THEN '(không rõ)'
         WHEN age < 18 THEN '<18'
         WHEN age < 25 THEN '18-24'
         WHEN age < 35 THEN '25-34'
         WHEN age < 45 THEN '35-44'
         ELSE '45+'
       END AS age_group,
       count(*) AS n_users
FROM (SELECT extract(year FROM age(date '2026-10-01', birth_date))::int AS age
      FROM users
      WHERE deleted_at IS NULL) a
GROUP BY 1
ORDER BY min(age);
