-- Create a table
--
DROP TABLE IF EXISTS customers;
GO
CREATE TABLE customers (tabkey int, customer_id nvarchar(10), customer_information varchar(1000));
GO
-- Populate 1 million rows of data into the table
--
with cte
as
(
select ROW_NUMBER() over(order by c1.object_id) id from sys.columns c1 cross join sys.columns c2
)
insert customers
select id, convert(nvarchar(10), id),'customer details' from cte
go
select count(*) FROM customers
go
-- Create a stored procedure to select a row
--
CREATE or ALTER PROC getcustomer @tabkey int
AS
SELECT * FROM customers WHERE tabkey = @tabkey;
GO
ALTER DATABASE [highcpu_missingindex] SET QUERY_STORE CLEAR;
GO
