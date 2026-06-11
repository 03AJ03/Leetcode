# Write your MySQL query statement below
WITH valid_stores as(
    SELECT store_id
    FROM inventory
    GROUP BY store_id
    HAVING COUNT(DISTINCT product_name)>=3
),
product_stats AS(
    SELECT store_id,product_name,price,SUM(quantity) AS total_quantity
    FROM inventory
    GROUP BY store_id,product_name,price
),
max_min AS(
    SELECT *,ROW_NUMBER() OVER(
        PARTITION BY store_id
        ORDER BY price desc , total_quantity desc
    ) as exp_rnk,
    ROW_NUMBER() OVER(
        PARTITION BY store_id
        ORDER BY price asc , total_quantity desc
    ) as ch_rnk
    FROM product_stats
)
SELECT
    s.store_id,
    s.store_name,
    s.location,
    e.product_name AS most_exp_product,
    c.product_name AS cheapest_product,
    ROUND(1.0*c.total_quantity / e.total_quantity, 2) AS imbalance_ratio
FROM stores s
JOIN valid_stores v
    ON s.store_id = v.store_id
JOIN max_min e
    ON s.store_id = e.store_id
   AND e.exp_rnk = 1
JOIN max_min c
    ON s.store_id = c.store_id
   AND c.ch_rnk = 1
WHERE c.total_quantity>e.total_quantity
ORDER BY imbalance_ratio DESC,
         s.store_name ASC;

