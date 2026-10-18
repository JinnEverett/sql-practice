-- sai: created_at < ts → mất id 102 và 101 (cùng phút 20)
SELECT id, created_at, title FROM r02.feed WHERE created_at < '2026-01-01 00:20+00' ORDER BY created_at DESC, id DESC LIMIT 7;
