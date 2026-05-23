# Write your MySQL query statement below
SELECT 
E2.unique_id,
E1.name
from Employees E1
LEFT JOIN EmployeeUNI E2 ON E2.id=E1.id;
