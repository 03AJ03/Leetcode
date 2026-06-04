# Write your MySQL query statement below
SELECT user_id, COUNT(prompt) as prompt_count, ROUND(AVG(tokens),2) as avg_tokens
FROM prompts
GROUP BY user_id
HAVING COUNT(*)>=3
AND MAX(tokens)>AVG(tokens)
ORDER BY avg_tokens desc,user_id asc;

