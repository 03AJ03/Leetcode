# Write your MySQL query statement below
SELECT 
    St.student_id,
    St.student_name,
    Sub.subject_name,
    COUNT(E.subject_name) AS attended_exams
FROM Students St
CROSS JOIN Subjects Sub
LEFT JOIN Examinations E
ON St.student_id = E.student_id
AND Sub.subject_name = E.subject_name
GROUP BY 
    St.student_id,
    St.student_name,
    Sub.subject_name
ORDER BY 
    St.student_id,
    Sub.subject_name;
