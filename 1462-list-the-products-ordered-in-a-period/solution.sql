# Write your MySQL query statement below
SELECT p.product_name , SUM(unit) AS unit
FROM Products p 
JOIN Orders o on o.product_id=p.product_id
WHERE MONTH(order_date)=2 AND YEAR(order_date)=2020
GROUP BY p.product_id,p.product_name
HAVING SUM(unit)>=100
