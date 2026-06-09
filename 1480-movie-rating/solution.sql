# Write your MySQL query statement below
(SELECT U.name as results
FROM Users U
JOIN MovieRating MR ON MR.user_id=U.user_id
GROUP BY U.user_id , U.name
ORDER BY COUNT(*) DESC , U.name asc
LIMIT 1
)
UNION ALL
(
SELECT M.title as results
FROM Movies M
JOIN MovieRating MR ON MR.movie_id=M.movie_id
WHERE MONTH(MR.created_at)='2' AND YEAR(MR.created_at)='2020'
GROUP BY M.movie_id,M.title
ORDER BY AVG(MR.rating) DESC,M.title asc
LIMIT 1
)


