-- Create a table
--
DROP TABLE IF EXISTS customers;
GO
CREATE TABLE customers (tabkey int, customer_id nvarchar(10) primary key nonclustered, customer_date datetime, customer_type char(500) not null);
GO
-- Populate 1 million rows of data into the table
--
with cte
as
(
select ROW_NUMBER() over(order by c1.object_id) id from sys.columns c1 cross join sys.columns c2
)
insert customers
select id, convert(nvarchar(10), id),getdate(), 'customer type'+convert(char(20), id) from cte
go
/* insert into customers select * from customers;
go
insert into customers select * from customers;
go */
-- Clear the query store to ensure statistics are new
--
ALTER DATABASE [waiting_memorygrant] SET QUERY_STORE CLEAR;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
ALTER DATABASE [waiting_memorygrant] SET COMPATIBILITY_LEVEL = 130;
GO

