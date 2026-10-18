-- sai: DELETE từng dòng — dữ liệu mất nhưng partition vẫn còn (và sinh dead tuple)
DELETE FROM r12.events_p WHERE ts < '2026-04-01 00:00+00';
