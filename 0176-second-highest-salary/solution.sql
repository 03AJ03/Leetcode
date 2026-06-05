# Write your MySQL query statement below
SELECT MAX(salary) AS SecondHighestSalary
FROM Employee 
WHERE SALARY<(
    SELECT MAX(SALARY)
    FROM EMPLOYEE
);
