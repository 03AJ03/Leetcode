# Write your MySQL query statement below
WITH cte AS(
    SELECT d.name as Department,e.name as Employee,e.salary AS Salary,
    DENSE_RANK() OVER(PARTITION BY e.departmentId ORDER BY e.salary desc) as rnk
    FROM Employee e
    JOIN Department d ON d.id=e.departmentId
)
SELECT Department,Employee,Salary
FROM cte
WHERE rnk=1
