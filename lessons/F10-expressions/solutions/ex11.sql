-- db: shop_m
-- mode: manual
-- Demo: shop_m có khách sinh 29/02 → make_date(2026, 2, 29) sẽ lỗi; to_char('MM-DD') thì không.
SELECT count(*) AS n_born_feb29 FROM users WHERE to_char(birth_date, 'MM-DD') = '02-29';
SELECT count(*) AS n_birthday_week FROM users
WHERE deleted_at IS NULL AND to_char(birth_date, 'MM-DD') BETWEEN '10-19' AND '10-25';
