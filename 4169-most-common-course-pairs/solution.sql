# Write your MySQL query statement below
WITH top_performers AS(
    SELECT user_id
    FROM course_completions
    GROUP BY user_id
    HAVING COUNT(course_id)>=5
    AND AVG(course_rating)>=4
),
course_sequence AS(
    SELECT c.user_id,
    course_name as first_course,
    LEAD(course_name) OVER (
        PARTITION BY user_id
        ORDER BY completion_date
    ) AS second_course
    FROM course_completions c
    JOIN top_performers t ON t.user_id=c.user_id
)
SELECT  first_course,
        second_course,
        COUNT(*) AS transition_count
FROM course_sequence
WHERE second_course IS NOT NULL
GROUP BY first_course, second_course
ORDER BY transition_count desc,first_course asc, second_course asc
