SELECT id, status, attempts, locked_by, last_error FROM r04.jobs WHERE status IN ('running', 'dead') OR last_error IS NOT NULL ORDER BY id;
