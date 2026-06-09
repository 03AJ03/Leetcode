# Write your MySQL query statement below
WITH cte as(
    SELECT 
    stock_name,
    CASE 
    WHEN operation='Buy' THEN -price
    ELSE price
    END AS price
    FROM Stocks
)
SELECT stock_name,
SUM(price) AS capital_gain_loss
FROM cte
GROUP BY stock_name
;
