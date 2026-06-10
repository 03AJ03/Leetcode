# Write your MySQL query statement below
WITH cte AS(
    SELECT E.employee_id,E.name ,PR.rating,
    ROW_NUMBER() OVER(
        PARTITION BY E.employee_id ORDER BY PR.review_date desc,PR.rating desc
    )AS rnk
    FROM Employees E 
    JOIN performance_reviews PR ON E.employee_id=PR.employee_id
)
SELECT employee_id,name,
MAX(CASE WHEN rnk=1 THEN rating END)-MAX(CASE WHEN rnk=3 THEN rating END) AS improvement_score
FROM cte
WHERE rnk <= 3
GROUP BY employee_id,name 
HAVING COUNT(*) = 3
AND MAX(CASE WHEN rnk=1 THEN rating END)>MAX(CASE WHEN rnk=2 THEN rating END)
AND MAX(CASE WHEN rnk=2 THEN rating END)>MAX(CASE WHEN rnk=3 THEN rating END)
ORDER BY improvement_score desc,name asc;
