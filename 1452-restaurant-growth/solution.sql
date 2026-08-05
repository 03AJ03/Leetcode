WITH cte AS(
    SELECT visited_on,SUM(amount) AS amount
    FROM Customer
    GROUP BY visited_on
    HAVING COUNT(customer_id)>=1
),
cte2 AS(
    SELECT visited_on,
    ROUND(SUM(amount) OVER( ORDER BY visited_on ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS amount,
    ROUND(AVG(amount) OVER( ORDER BY visited_on ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS average_amount,
    ROUND(COUNT(*) OVER( ORDER BY visited_on ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS num_days
    FROM cte
)
-- SELECT visited_on,amount,average_amount
SELECT visited_on,amount,average_amount
FROM cte2
WHERE num_days=7
ORDER BY visited_on
