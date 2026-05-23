# Write your MySQL query statement below
SELECT c1.name
from Customer c1
LEFT JOIN Customer c2 ON c1.id=c2.id
WHERE c2.referee_id!=2 OR c2.referee_id IS NULL;
