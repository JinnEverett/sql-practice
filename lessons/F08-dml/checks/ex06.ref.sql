DELETE FROM f08.subscribers s USING f08.subscribers k
WHERE lower(trim(k.email)) = lower(trim(s.email)) AND (k.created_at, k.id) < (s.created_at, s.id);
