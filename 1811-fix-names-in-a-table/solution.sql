# Write your MySQL query statement below
SELECT user_id,
CONCAT(
    UPPER(LEFT(NAME,1)),
    LOWER(SUBSTRING(NAME,2)) 
)AS name
FROM Users
ORDER BY user_id;
