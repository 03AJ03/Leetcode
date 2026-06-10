# Write your MySQL query statement below
WITH first_half AS (
    SELECT driver_id,
    AVG
        (distance_km/fuel_consumed)
         AS first_half_avg
    FROM trips
    WHERE MONTH(trip_date) in (1,2,3,4,5,6)
    GROUP BY driver_id
)
,second_half AS (
    SELECT driver_id,
    AVG(
        distance_km/fuel_consumed)
     AS second_half_avg
    FROM trips
    WHERE MONTH(trip_date) in (7,8,9,10,11,12)
    GROUP BY driver_id
)
SELECT d.driver_id,d.driver_name,ROUND(fh.first_half_avg,2) as first_half_avg,ROUND(sh.second_half_avg,2) AS second_half_avg,
ROUND(sh.second_half_avg - fh.first_half_avg,2) AS efficiency_improvement
FROM drivers d
JOIN first_half fh ON fh.driver_id=d.driver_id
JOIN second_half sh ON sh.driver_id=d.driver_id
WHERE sh.second_half_avg>fh.first_half_avg
ORDER BY efficiency_improvement DESC,d.driver_name ASC;
