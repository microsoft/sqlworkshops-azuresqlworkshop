CREATE or ALTER PROC getcustomer_byid @customer_id int
AS
SELECT * FROM customers WHERE customer_id = @customer_id;
GO

