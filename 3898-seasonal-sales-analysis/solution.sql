WITH cte as(
    SELECT 
       CASE
            WHEN MONTH(S.sale_date) IN (12,1,2) THEN 'Winter'
            WHEN MONTH(S.sale_date) IN (3,4,5) THEN 'Spring'
            WHEN MONTH(S.sale_date) IN (6,7,8) THEN 'Summer'
            ELSE 'Fall'
        END AS season,
        P.category,
        SUM(quantity) AS total_quantity,
        SUM(quantity * price) AS total_revenue,
        ROW_NUMBER() OVER(
            PARTITION BY CASE
            WHEN MONTH(S.sale_date) IN (12,1,2) THEN 'Winter'
            WHEN MONTH(S.sale_date) IN (3,4,5) THEN 'Spring'
            WHEN MONTH(S.sale_date) IN (6,7,8) THEN 'Summer'
            ELSE 'Fall'
            END
        ORDER BY SUM(quantity) DESC,
            SUM(quantity * price) DESC,P.category ASC
        )AS rnk
    FROM Sales S
    JOIN Products P ON S.product_id = P.product_id
    GROUP BY season, P.category
)
SELECT season,category,total_quantity,total_revenue
FROM cte
where rnk=1
