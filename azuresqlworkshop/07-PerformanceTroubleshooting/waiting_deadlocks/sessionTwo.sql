begin tran
 
update [SalesLT].Customer set FirstName = 'Carlos' where CustomerID = 19
waitfor delay '00:00:05'
update [SalesLT].[Address] set City = 'Arlington' where AddressID = 25
 
rollback