# Write your MySQL query statement below
WITH cte AS(
    SELECT id,salary,
    DENSE_RANK() OVER (ORDER BY salary desc) AS rnk
    FROM Employee
)
SELECT MAX(salary) AS SecondHighestSalary
FROM cte 
WHERE rnk=2
