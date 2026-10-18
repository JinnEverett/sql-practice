-- db: lab
-- ordered
SELECT id, name, external_ref FROM f02.partners
WHERE external_ref::uuid = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid ORDER BY id;
