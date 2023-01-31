begin tran
delete
	s
from
	[SalesLT].[SalesOrderDetail] s
where
	SalesOrderID = 71915;
go
-- Rollback so when blocking frees up we can run it again
--
rollback tran;
go