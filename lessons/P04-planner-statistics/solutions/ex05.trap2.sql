CREATE STATISTICS addr_nd (ndistinct) ON city, zip FROM p04.addr;
ANALYZE p04.addr;
