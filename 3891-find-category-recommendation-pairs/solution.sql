# Write your MySQL query statement below
WITH DistCat AS(
    SELECT DISTINCT
    pp.user_id,pin.category
    FROM ProductPurchases pp
    JOIN ProductInfo pin ON pin.product_id=pp.product_id
)
SELECT d1.category as category1,
d2.category as category2,
COUNT(DISTINCT d1.user_id) AS customer_count
FROM DistCat d1
JOIN DistCat d2 ON d1.user_id=d2.user_id
AND d1.category < d2.category
GROUP BY
    d1.category,
    d2.category
HAVING COUNT(DISTINCT d1.user_id) >= 3
ORDER BY
    customer_count DESC,
    category1,
    category2;

