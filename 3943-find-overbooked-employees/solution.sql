# Write your MySQL query statement below
WITH weekly AS(
    SELECT employee_id,
    YEARWEEK(meeting_date,1) AS week_id,
    SUM(duration_hours) AS hours
    FROM meetings
    GROUP BY employee_id,week_id
),
meeting_heavy AS(
    SELECT employee_id,
    count(*) AS meeting_heavy_weeks
    FROM weekly
    where hours>20
    GROUP BY employee_id
    HAVING COUNT(*) >= 2
)
SELECT e.employee_id,e.employee_name,e.department,
m.meeting_heavy_weeks AS meeting_heavy_weeks
FROM employees e
JOIN meeting_heavy m ON m.employee_id=e.employee_id
ORDER BY m.meeting_heavy_weeks desc,e.employee_name asc
