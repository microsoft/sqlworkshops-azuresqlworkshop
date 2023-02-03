CREATE NONCLUSTERED INDEX [idx_customers_customer_date]
ON [dbo].[customers] ([customer_date], [customer_type])
INCLUDE (customer_id);
GO