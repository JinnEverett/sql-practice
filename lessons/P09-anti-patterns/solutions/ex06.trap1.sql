-- query
SELECT least(count(*), 1001) FROM events WHERE event_type = 'search';
