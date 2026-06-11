# Write your MySQL query statement below
WITH purchase AS(
    SELECT customer_id,COUNT(customer_id) as purchase_count
    FROM customer_transactions
    WHERE transaction_type='purchase'
    GROUP BY customer_id
    HAVING COUNT(*)>=3
),
active AS(
    SELECT customer_id
    FROM customer_transactions
    GROUP BY customer_id
    HAVING DATEDIFF(MAX(transaction_date),MIN(transaction_date))>=30
),
refund AS(
    SELECT customer_id,COUNT(customer_id) as refund_count
    FROM customer_transactions
    WHERE transaction_type='refund'
    GROUP BY customer_id
)

SELECT 
p.customer_id 
from purchase p
JOIN active a ON a.customer_id=p.customer_id
LEFT JOIN refund r ON r.customer_id=P.customer_id
WHERE IFNULL(r.refund_count,0)*1.0/(p.purchase_count+COALESCE(r.refund_count, 0))<0.2
ORDER BY customer_id
