# Write your MySQL query statement below
SELECT U.name,IFNULL(SUM(R.distance),0) as travelled_distance
FROM Users U
LEFT JOIN Rides R ON R.user_id=U.id
GROUP BY U.name,U.id
ORDER BY travelled_distance desc , U.name asc;
