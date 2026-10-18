SELECT id, status, attempts, locked_by, locked_at IS NOT NULL AS locked FROM r04.jobs ORDER BY id;
