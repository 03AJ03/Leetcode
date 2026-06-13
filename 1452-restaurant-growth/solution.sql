WITH daily AS (
    SELECT
        visited_on,
        SUM(amount) AS amount
    FROM Customer
    GROUP BY visited_on
),
windowed AS (

    SELECT
        visited_on,
        SUM(amount)  OVER w        AS amount,
        ROUND(AVG(amount) OVER w, 2) AS average_amount,
        COUNT(*)     OVER w        AS day_count
    FROM daily
    WINDOW w AS (
        ORDER BY visited_on
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )
)
SELECT visited_on, amount, average_amount
FROM windowed
WHERE day_count = 7
ORDER BY visited_on;
