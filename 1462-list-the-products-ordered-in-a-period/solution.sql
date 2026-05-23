# Write your MySQL query statement below
SELECT P.product_name,sum(O.unit) AS unit
from Products P
JOIN Orders O on P.product_id=O.product_id
WHERE month(O.order_date)=2 AND YEAR(O.order_date)=2020
GROUP BY P.product_name
HAVING sum(O.unit)>=100;
