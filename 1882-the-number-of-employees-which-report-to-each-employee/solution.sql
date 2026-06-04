# Write your MySQL query statement below
SELECT E1.employee_id,E1.name,
COUNT(*) AS reports_count,
ROUND(AVG(E2.age)) AS average_age
FROM Employees E1
JOIN Employees E2 ON 
E1.employee_id=E2.reports_to
GROUP BY employee_id,E1.name
HAVING COUNT(*)>=1
ORDER BY employee_id asc;
;
