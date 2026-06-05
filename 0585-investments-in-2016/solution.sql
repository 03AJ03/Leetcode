# Write your MySQL query statement below
SELECT ROUND(SUM(A.tiv_2016),2) as tiv_2016
FROM Insurance A
WHERE tiv_2015 IN(
    SELECT tiv_2015
    FROM Insurance
    GROUP BY tiv_2015
    HAVING COUNT(*) > 1
)
AND (lat,lon) IN (
    SELECT lat,lon
    FROM Insurance
    Group by LAT,LON
    having count(*)=1
)
