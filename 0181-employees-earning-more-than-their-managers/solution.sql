# Write your MySQL query statement below
SELECT e1.name as Employee
from Employee e1
JOIN Employee e2
On e1.managerID=e2.id
where e1.salary>e2.salary;
