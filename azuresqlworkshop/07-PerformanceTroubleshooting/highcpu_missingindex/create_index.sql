CREATE NONCLUSTERED INDEX [idx_customer_tabkey]
ON [dbo].[customers] ([tabkey])
WITH (ONLINE = ON, RESUMABLE = ON);
GO
