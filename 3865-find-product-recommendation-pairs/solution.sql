# Write your MySQL query statement below
SELECT 
    p1.product_id   AS product1_id,
    p2.product_id   AS product2_id,
    pi1.category    AS product1_category,
    pi2.category    AS product2_category,
    COUNT(*)        AS customer_count
FROM ProductPurchases p1
JOIN ProductPurchases p2
    ON  p1.user_id    = p2.user_id
    AND p1.product_id < p2.product_id       -- avoids duplicates & self-pairs
JOIN ProductInfo pi1 ON p1.product_id = pi1.product_id
JOIN ProductInfo pi2 ON p2.product_id = pi2.product_id
GROUP BY p1.product_id, p2.product_id, pi1.category, pi2.category
HAVING COUNT(*) >= 3
ORDER BY customer_count DESC, product1_id ASC, product2_id ASC;
