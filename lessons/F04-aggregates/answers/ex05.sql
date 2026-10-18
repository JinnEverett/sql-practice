select event_type, count(*) as n_events, count(user_id) as n_logged_in_events, count(distinct user_id) as n_users from events group by event_type order by event_type asc;
