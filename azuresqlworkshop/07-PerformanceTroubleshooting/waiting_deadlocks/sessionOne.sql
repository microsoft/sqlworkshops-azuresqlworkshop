begin tran
 
update [SalesLT].[Address] set City = 'Arlington' where AddressID = 25
waitfor delay '00:00:10'
update [SalesLT].Customer set FirstName = 'Carlos' where CustomerID = 19
 
rollback