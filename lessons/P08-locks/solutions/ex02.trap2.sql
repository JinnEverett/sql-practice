UPDATE p08.jobs SET state = 'taken'
WHERE id = (SELECT id FROM p08.jobs WHERE state = 'new' ORDER BY id LIMIT 1 FOR UPDATE NOWAIT);
