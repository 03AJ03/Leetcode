# Write your MySQL query statement below
SELECT
    R.contest_id,
    ROUND(
        COUNT(U.user_id) * 100.0 /
        (SELECT COUNT(*) FROM Users),
        2
    ) AS percentage
FROM Register R
JOIN Users U ON R.user_id = U.user_id
GROUP BY R.contest_id
ORDER BY percentage DESC, R.contest_id ASC;

