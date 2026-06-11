
WITH last_event AS (
    
    SELECT
        user_id,
        event_type,
        plan_name                        AS current_plan,
        monthly_amount                   AS current_monthly_amount,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY event_date DESC
        )                                AS rn
    FROM subscription_events
),

active_users AS (
    
    SELECT user_id, current_plan, current_monthly_amount
    FROM  last_event
    WHERE rn = 1
      AND  event_type != 'cancel'
),

downgrade_users AS (
    
    SELECT DISTINCT user_id
    FROM  subscription_events
    WHERE event_type = 'downgrade'
),

revenue_stats AS (

    SELECT
        user_id,
        MAX(monthly_amount)                     AS max_historical_amount,
        DATEDIFF(MAX(event_date), MIN(event_date)) AS days_as_subscriber
    FROM  subscription_events
    GROUP BY user_id
)

SELECT
    a.user_id,
    a.current_plan,
    a.current_monthly_amount,
    r.max_historical_amount,
    r.days_as_subscriber
FROM       active_users   a
JOIN       downgrade_users d ON a.user_id = d.user_id
JOIN       revenue_stats   r ON a.user_id = r.user_id
WHERE
    a.current_monthly_amount < r.max_historical_amount * 0.5  
    AND r.days_as_subscriber >= 60                             
ORDER BY
    r.days_as_subscriber DESC,
    a.user_id ASC;

