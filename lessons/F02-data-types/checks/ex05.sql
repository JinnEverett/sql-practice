-- db: lab
-- ordered
SELECT id, amount FROM f02.legacy_wallet
WHERE round(amount::numeric, 2) = 0.30 ORDER BY id;
