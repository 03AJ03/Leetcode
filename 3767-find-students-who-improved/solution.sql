# Write your MySQL query statement below
WITH ranked AS(
    SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY student_id,subject
        ORDER BY exam_date asc
    )AS rnk_f,
    ROW_NUMBER() OVER(
        PARTITION BY student_id,subject
        ORDER BY exam_date desc
    )AS rnk_l
    FROM Scores
),
first AS(
    SELECT student_id,subject,score as first_score
    FROM ranked
    where rnk_f=1
),
last AS(
    SELECT student_id,subject,score as latest_score
    FROM ranked
    where rnk_l=1
)
SELECT f.student_id,f.subject,f.first_score,l.latest_score
FROM first f
JOIN last l ON l.student_id=f.student_id
AND l.subject=f.subject
WHERE l.latest_score>f.first_score

