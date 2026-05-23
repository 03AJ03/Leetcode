# Write your MySQL query statement below
SELECT E.name as name, B.bonus
from Employee E
LEFT JOIN Bonus B on E.empId=B.empId
where B.bonus<1000 OR B.bonus IS null;
