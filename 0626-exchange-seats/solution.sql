# Write your MySQL query statement below
SELECT CASE
WHEN id%2=1 and id+1 IN (SELECT id from Seat) THEN id+1
WHEN id%2=0 THEN id-1
else id
END AS id,
STUDENT
FROM SEAT
ORDER BY id;
