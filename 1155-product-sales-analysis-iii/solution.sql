# Write your MySQL query statement below
WITH min_year AS(
    SELECT product_id,quantity,price,year,
    DENSE_RANK() OVER (PARTITION BY product_id ORDER BY year asc) AS rnk
    FROM Sales
)
SELECT product_id,year as first_year,quantity,price
from min_year
where rnk=1
