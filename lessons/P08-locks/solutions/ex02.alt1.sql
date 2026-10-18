WITH c AS (SELECT id FROM p08.jobs WHERE state = 'new' ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED)
UPDATE p08.jobs j SET state = 'taken' FROM c WHERE j.id = c.id;
