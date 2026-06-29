# Write your MySQL query statement below
SELECT
    request_at AS Day,
    ROUND(
        SUM(status != 'completed') / COUNT(*),
        2
    ) AS "Cancellation Rate"
FROM Trips t
JOIN Users c
ON t.client_id = c.users_id
JOIN Users d
ON t.driver_id = d.users_id
WHERE c.banned = 'No'
AND d.banned = 'No'
AND request_at BETWEEN '2013-10-01' AND '2013-10-03'
GROUP BY request_at
HAVING COUNT(t.id)>=1;
