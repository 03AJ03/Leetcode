# Write your MySQL query statement below
SELECT Department,
Employee,
Salary
FROM
(SELECT D.name as Department,
E.name as Employee,
E.salary as Salary,
DENSE_RANK() OVER(
    PARTITION BY E.departmentId
    ORDER BY E.salary desc
    )AS rankk
FROM Employee E
JOIN Department D ON E.departmentId=D.id
)t
WHERE rankk=1;
