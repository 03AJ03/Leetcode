# Write your MySQL query statement below
WITH first_positive AS(
    SELECT patient_id,
    MIN(test_date) as first_positive_date
    FROM covid_tests
    WHERE result='positive'
    GROUP BY patient_id
),
first_negative AS(
    SELECT fp.patient_id,
    MIN(ct.test_date) as first_negative_date
    FROM first_positive fp
    JOIN covid_tests ct
        ON fp.patient_id = ct.patient_id
    WHERE result='negative'
    AND ct.test_date > fp.first_positive_date
    GROUP BY patient_id
)
SELECT
    P.patient_id,
    P.patient_name,
    P.age,
    DATEDIFF(
        fn.first_negative_date,
        fp.first_positive_date
    ) AS recovery_time
FROM patients P
JOIN first_positive fp ON fp.patient_id=P.patient_id
JOIN first_negative fn ON fn.patient_id=P.patient_id
GROUP BY 
    P.patient_id,
    P.patient_name,
    P.age
ORDER BY
    recovery_time ASC,
    P.patient_name ASC;
