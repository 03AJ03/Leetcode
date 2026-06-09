# Write your MySQL query statement below
with cte as (
    select person_name, sum(weight) over(order by turn) as bus_weight from Queue
)
select person_name from cte 
where bus_weight<=1000 
order by bus_weight desc limit 1
