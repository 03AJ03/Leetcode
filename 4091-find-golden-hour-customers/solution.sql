WITH cust_stats AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        SUM(
            CASE
                WHEN TIME(order_timestamp) BETWEEN '11:00:00' AND '14:00:00'
      OR TIME(order_timestamp) BETWEEN '18:00:00' AND '21:00:00'
                THEN 1
                ELSE 0
            END
        ) AS peak_orders,
        COUNT(order_rating) AS rated_orders,
        AVG(order_rating) AS average_rating
    FROM restaurant_orders
    GROUP BY customer_id
)

SELECT
    customer_id,
    total_orders,
    ROUND(100.0 * peak_orders / total_orders) AS peak_hour_percentage,
    ROUND(average_rating, 2) AS average_rating
FROM cust_stats
WHERE total_orders >= 3
  AND peak_orders >= 0.6 * total_orders
  AND rated_orders >= 0.5 * total_orders
  AND average_rating >= 4
ORDER BY average_rating DESC,
         customer_id DESC;
