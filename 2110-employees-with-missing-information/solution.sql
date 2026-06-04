# Write your MySQL query statement below
SELECT employee_id
FROM Employees
UNION
SELECT employee_id
FROM Salaries
EXCEPT
SELECT E.employee_id
FROM Employees E
JOIN Salaries S
ON E.employee_id = S.employee_id
ORDER BY employee_id;
