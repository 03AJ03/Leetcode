# Write your MySQL query statement below
SELECT P.project_id, ROUND(avg(E.experience_years),2) as average_years
from project P
JOIN Employee E ON E.employee_id=P.employee_id
GROUP BY P.project_id;

