# Write your MySQL query statement below
SELECT customer_number
FROM Orders
group by customer_number
order by count(order_number) desc
limit 1;
