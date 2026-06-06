# Write your MySQL query statement below
WITH a AS
(
    SELECT requester_id as id
    FROM RequestAccepted
    UNION ALL
    SELECT accepter_id as id
    FROM RequestAccepted
    )
SELECT id, COUNT(id) AS num
FROM a
GROUP BY id
ORDER BY COUNT(id) DESC
LIMIT 1

