select id, name, external_ref from f02.partners
where replace(external_ref,'-','') ilike replace('%a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11%','-','')
order by id asc;
