begin tran
insert into [SalesLT].[SalesOrderDetail] (
	SalesOrderID
	,OrderQty
	,ProductID
	,UnitPrice
	)
select
	71946 as SalesOrderID
	,OrderQty
	,ProductID
	,UnitPrice
from 
	[SalesLT].[SalesOrderDetail]
where
	SalesOrderID = 71938
	and SalesOrderDetailID = 113311;
go
-- Rollback so when blocking frees up we can run it again
--
rollback tran;
go