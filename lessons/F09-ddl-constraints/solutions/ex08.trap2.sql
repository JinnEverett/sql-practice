CREATE TABLE f09.employees (id int PRIMARY KEY, full_name text NOT NULL,
  manager_id int REFERENCES f09.employees (id) ON DELETE SET NULL, work_email text UNIQUE NULLS NOT DISTINCT, CHECK (manager_id <> id));
