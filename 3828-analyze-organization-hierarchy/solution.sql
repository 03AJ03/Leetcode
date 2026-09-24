# Write your MySQL query statement below
WITH RECURSIVE hierarchy AS (

    -- CEO starts at level 1
    SELECT
        employee_id,
        employee_name,
        manager_id,
        salary,
        1 AS level
    FROM Employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Find employees under each manager
    SELECT
        e.employee_id,
        e.employee_name,
        e.manager_id,
        e.salary,
        h.level + 1
    FROM Employees e
    JOIN hierarchy h
        ON e.manager_id = h.employee_id
),

subtree AS (

    -- Every employee is initially under themselves
    SELECT
        employee_id AS manager_id,
        employee_id AS employee_id,
        salary
    FROM Employees

    UNION ALL

    -- Find direct and indirect employees
    SELECT
        s.manager_id,
        e.employee_id,
        e.salary
    FROM subtree s
    JOIN Employees e
        ON e.manager_id = s.employee_id
),

stats AS (

    SELECT
        manager_id,
        COUNT(*) - 1 AS team_size,
        SUM(salary) AS budget
    FROM subtree
    GROUP BY manager_id
)

SELECT
    h.employee_id,
    h.employee_name,
    h.level,
    s.team_size,
    s.budget
FROM hierarchy h
JOIN stats s
    ON h.employee_id = s.manager_id
ORDER BY
    h.level ASC,
    s.budget DESC,
    h.employee_name ASC;
