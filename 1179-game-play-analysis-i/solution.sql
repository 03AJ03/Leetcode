# Write your MySQL query statement below
SELECT player_id,
Min(event_date) as first_login
FROM
Activity
GROUP BY player_id;
