WITH RECURSIVE walk (start_id, id, manager_id) AS (
  SELECT id, id, manager_id FROM i02.emp_import
  UNION ALL
  SELECT w.start_id, e.id, e.manager_id FROM walk w JOIN i02.emp_import e ON e.id = w.manager_id
) CYCLE id SET is_cycle USING path
SELECT DISTINCT start_id AS id FROM walk WHERE is_cycle ORDER BY id;
