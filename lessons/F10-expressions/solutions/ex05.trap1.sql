SELECT CASE WHEN age IS NULL THEN '(không rõ)' WHEN age < 18 THEN '<18' WHEN age < 25 THEN '18-24' WHEN age < 35 THEN '25-34'
            WHEN age < 45 THEN '35-44' ELSE '45+' END AS age_group, count(*) AS n_users
FROM (SELECT (2026 - extract(year FROM birth_date))::int AS age FROM users WHERE deleted_at IS NULL) a GROUP BY 1 ORDER BY min(age);
