# Write your MySQL query statement below
SELECT class
From courses 
group by class
having count(student)>=5;
