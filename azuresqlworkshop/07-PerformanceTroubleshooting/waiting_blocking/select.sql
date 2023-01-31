begin tran
set transaction isolation level serializable
select
	*
from
	[SalesLT].[SalesOrderDetail];
GO

