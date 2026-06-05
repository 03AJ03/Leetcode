# Write your MySQL query statement below
SELECT ROUND(
    COUNT(DISTINCT A.player_id)/
    (SELECT COUNT(DISTINCT player_id) FROM Activity)
    ,2
)AS fraction
FROM ACTIVITY A
JOIN (
    SELECT player_id,
    MIN(event_date) AS first_login
    FROM Activity
    GROUP BY player_id
)B
ON A.player_id=B.player_id
AND A.event_date=DATE_ADD(B.first_login,INTERVAL 1 DAY);
