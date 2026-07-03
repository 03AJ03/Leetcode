WITH RECURSIVE level_cte AS (
    -- CEO
    SELECT
        employee_id,
        employee_name,
        manager_id,
        salary,
        1 AS level
    FROM Employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT
        e.employee_id,
        e.employee_name,
        e.manager_id,
        e.salary,
        l.level + 1
    FROM Employees e
    JOIN level_cte l
        ON e.manager_id = l.employee_id
),

hierarchy AS (
    -- Every employee is their own descendant
    SELECT
        employee_id AS manager,
        employee_id AS subordinate
    FROM Employees

    UNION ALL

    -- Expand descendants
    SELECT
        h.manager,
        e.employee_id
    FROM hierarchy h
    JOIN Employees e
        ON e.manager_id = h.subordinate
)

SELECT
    l.employee_id,
    l.employee_name,
    l.level,
    COUNT(h.subordinate) - 1 AS team_size,
    SUM(e.salary) AS budget
FROM level_cte l
JOIN hierarchy h
    ON l.employee_id = h.manager
JOIN Employees e
    ON h.subordinate = e.employee_id
GROUP BY
    l.employee_id,
    l.employee_name,
    l.level
ORDER BY
    l.level,
    budget DESC,
    l.employee_name;
