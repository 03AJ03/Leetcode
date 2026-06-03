# Write your MySQL query statement below
SELECT U.name as NAME, SUM(T.amount) AS BALANCE
FROM Users U
LEFT JOIN Transactions T ON T.account=U.account
GROUP BY U.account
HAVING sum(T.amount)>10000;
