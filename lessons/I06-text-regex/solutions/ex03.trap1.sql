SELECT id, phone, '+84' || regexp_replace(regexp_replace(phone, '\D', ''), '^(84|0)', '') AS phone_e164
FROM users WHERE id <= 60 AND phone IS NOT NULL ORDER BY id;
