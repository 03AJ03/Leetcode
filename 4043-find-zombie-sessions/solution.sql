WITH SessionStats AS (

SELECT
session_id,
user_id,
TIMESTAMPDIFF(
    MINUTE,
    MIN(event_timestamp),
    MAX(event_timestamp)
) AS session_duration_minutes,

COUNT(CASE WHEN event_type='scroll' THEN 1 END) scroll_count,

COUNT(CASE WHEN event_type='click' THEN 1 END) click_count,

COUNT(CASE WHEN event_type='purchase' THEN 1 END) purchase_count

FROM app_events
GROUP BY session_id,user_id

)
SELECT session_id,user_id,
session_duration_minutes,
scroll_count
FROM SessionStats
WHERE session_duration_minutes>30
AND scroll_count>=5
AND purchase_count=0
AND click_count/scroll_count<0.2
ORDER BY scroll_count desc,session_id asc;
