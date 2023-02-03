SELECT customer_id, customer_type, customer_date
FROM customers
WHERE customer_date < GETDATE()
ORDER BY customer_date, customer_type;
GO