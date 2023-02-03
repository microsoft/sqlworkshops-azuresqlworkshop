# Steps to troubleshooting a performance problem due to waiting because of excessive memory grants

Use the following steps to reproduce, monitor, and resolve a high CPU condition for an Azure SQL Database because of a lack of resoures

## Setup

Setup the problem using the following steps:

1. Deploy an Azure SQL Database using the General Purpose Service Tier using the Provisioned Compute Tier with 2 vCores
2. Connect to Azure SQL Database using a tool like SSMS or Azure Data Studio and run the script customer_ddl.sql. This script will create a table, populate data into the table, and create stored procedure(s). It will take ~30 seconds to run this script.
3. Install the tool ostress.exe from https://aka.ms/ostress.exe.
4. Edit the script workload.cmd to put in your logical server, database name, admin user name, and admin password.

## Reproduce, analyze and resolve the waiting problem

Note: You will see more of a clear picture of high CPU if you wait for one hour AFTER creating the database and table with data to reproduce the problem.

5. Run workload 5 1. This will take 5 minutes to complete.
6. While this is running run troubleshooting_query.sql about 5 times. Notice the IO_QUEUE_LIMIT and IO_COMPLETION waits. You might also see RESOURCE_SEMAPHORE waits. The troubleshooing_query.sql file is designed to look for waits from queries using parallelism which is why you might see session_id more than once. IO_COMPLETION is a sign of tempdb spills. IO_QUEUE_LIMIT is a throttle from our service tier and vCore choice on I/O and RESOURCE_SEMAPHORE is a throttle to not allow memory grants to consume SQL Server memory.
7. Let workload complete.
8. Look at Azure Portal to see "some" CPU (could be "jagged") but high Data I/O
9. Look at Top Resource Consuming Queries. Notice on right hand side the average duration is very high. Switch to CPU and see that CPU was a low part of that. A big sign of waiting.
9. Notice the query is using a Table Scan and a sort.
10. Notice also in Query Wait Statistics a high nuber of waits and other disk I/O. Other disk I/O can be tempdb spills which can occur when memory grants are very high but with an incorrect estimate.
11. Bring up selectquery.sql, select the Actual Execution Plan, and run the query. Notice in the plan the warning for a sort spill. This query takes about 1.5 minutes to complete before you can see the plan.
12. Notice the dbcompat level is 130. If we use dbcompat 150 or 160 we can take advantage of memory grant feedback. Use SSMS to change the dbcompat to 160.
13. Now bring up the selectquery.sql file, select Actual Execution Plan, and run the query. The sort warning is still there but also notice an index recommendation. The query still takes 1.5 mins to run.
14. Run the query again. This time it only takes about 20 seconds and the sort warning and spill are gone. 
15. Bring up query_store_feedback.sql. Notice that the feedback is persisted in the query store so it will always be used in the future for this plan.
16. With our workload test tool ostress we will get a different query signature so in order to get feedback run workload 1 2. This will take around 1 in 40 seconds to finish.
14. Run workload 5 1 again. This will take only 30 seconds minutes to complete. So let's crank it up by running workload 5 5. This will take around 2 mins and 30 seconds.
15. Run troubleshooting_query.sql again and now we see RESOURCE_SEMAPHORE waits. So we have avoided the spills but the grants are still large enough to cause waits because of the large sort
16. We saw there is a missing index so let's create it but slightly modify the suggestion to include both columns from the sort. Run create_index.sql.
17. Run selectquery.sql. Now the sort and scan are gone. Still takes about 13 seconds.
18. Run workload 5 5 again. It will take about 1 minute to run.
19. While it is running run troubleshooting_query.sql again. Notice no waits.
20. Observe the portal and see we now have a very high CPU problem to deal with. 
21. Looking at the query this is because it using the index but having to seek all rows due to the WHERE clause. We need to consider revising the WHERE cause to narrow down the rows really needed. Also look at the table definition. The customer_type is char(500) not null which pads any values to 500 characters for all rows. This is probably not needed and can be changed to varchar(500) which will greatly reduce the number of pages needed to even seek all rows.
