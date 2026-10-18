SELECT format('INSERT INTO p10b.dst VALUES (%s, %s, %L);', id, v, pad) FROM p10b.src \gexec
