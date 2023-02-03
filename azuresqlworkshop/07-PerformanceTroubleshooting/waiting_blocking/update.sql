begin tran
update
	s
set
	s.OrderQty = 12
from
	[SalesLT].[SalesOrderDetail] s
where
	SalesOrderID = 71936
	and SalesOrderDetailID = 113257;
go
-- Rollback so when blocking frees up we can run it again
--
rollback tran;
go