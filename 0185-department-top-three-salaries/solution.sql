# Write your MySQL query statement below
WITH rnk AS(
    SELECT id,name,salary,departmentId,
    DENSE_RANK() OVER(
        PARTITION BY departmentId
        ORDER BY salary DESC
    ) AS rnk
    FROM Employee
)
SELECT d.name as Department,
r.name AS Employee,
r.salary AS Salary
FROM department d
JOIN rnk r ON r.departmentId=d.id
where r.rnk<=3;
