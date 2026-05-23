# Write your MySQL query statement below
SELECT C.name as Customers
FROM Customers C
Where C.id NOT IN (
    Select O.customerId
    from orders O
)
