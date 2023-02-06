# Steps to troubleshoot a waiting problem due to memory grants

Use the following steps to reproduce, monitor, and resolve a waiting problem due to memory grants.

## Setup

Setup the problem using the following steps:

1. Deploy an Azure SQL Database using the General Purpose Service Tier using the Provisioned Compute Tier with 2 vCores. Use the following resource to see a quick start on how to create an Azure SQL Database: <https://learn.microsoft.com/azure/azure-sql/database/single-database-create-quickstart>. I used the database name of **waiting_memorygrant**. You can use that name or if use your own you will need to edit scripts in this example to match your database name.
1. Edit the script **customer_ddl.sql** to put in your database name (if not waiting_memorygrant) for the ALTER DATABASE statements to clear the query store after table creation and data load, clear the procedure cache, and set dbcompat to 130.
1. Connect to Azure SQL Database with SQL Server Management Studio (SSMS) and run the script **customer_ddl.sql**. This script will create a table and populate data into the table. Use the following resource to see how to connect and run a query to Azure SQL Database with SSMS: <https://learn.microsoft.com/azure/azure-sql/database/connect-query-ssms?view=azuresql>
1. Edit the script **workload.cmd** to put in your logical server, database name, admin user name, and admin password. These scripts use the **ostress.exe** tool.

## Reproduce and analyze a tempdb spill problem due to memory grants

**Note:** You can reproduce the problem immediately but if you wait for 60 minutes the metrics in the Azure Portal are "cleaner" as they will not show any resources from creating the table and loading data.

1. Run workload.cmd with the following parameters:

    `workload 5 1`

    5 is the number of concurrent users<br>
    1 is the number of repetitions for each user

    This will take ~5 minutes to complete.

1. **While** this workload is running load and execute in SSMS the SQL script **troubleshooting_query.sql** about 5 times. Notice the IO_QUEUE_LIMIT and IO_COMPLETION waits. You might also see RESOURCE_SEMAPHORE waits. The troubleshooing_query.sql file is designed to look for waits from queries using parallelism which is why you might see session_id more than once. IO_COMPLETION is a sign of tempdb spills. IO_QUEUE_LIMIT is a throttle due to the service tier and vCore choice on I/O (only seen in Azure SQL). And RESOURCE_SEMAPHORE is a throttle to not allow memory grants to consume SQL Server memory.
1. Let workload.cmd script complete.
1. Using the Azure Portal for the Azure SQL Database select Overview in the resource menu on the left. Then select the Monitoring tab. Scroll down to view the Compute Utilization chart. Notice some CPU but also notice a high % of Data IO.
1. In Object Explorer, expand the Query Store folder under the database. Run the Top Resource Consuming Queries report. Notice on right hand page when you "hover" over the dot the average duration is very high. Switch the report Metric to Total CPU and hover over the dot on the right. You can see the average CPU was a small part of the long average duration. This is a sign of waiting.
1. Notice the query is using a Table Scan and a sort. The query text is the one we need to debug further. The plan shown is the estimated query plan.
1. Change the report Metric to Total Wait Time. Hover over the largest bar in the chart and see that the total wait times are mostly Other Data IO (likely because of the tempdb spill), CPU, and Memory. Let's run the individual query listed in the Query Store report using SSMS to look at the actual execution plan.

## Analyze the actual execution plan of the query

1. Load the script **selectquery.sql** in SSMS, select the Actual Execution Plan button (or `<Ctrl>+<M>`), and execute the query. This query takes about 1.5 minutes to complete before you can see the plan. Notice in the execution plan in the lower pane a Warning icon for the Sort operator. Hover over the Sort operator and look at the warning for a tempdb spill.

## Resolve the tempdb spill problem

1. In Object Explorer right click on your database and select Properties. Then select Options. Notice the second field from the top is Compatibility level. The current value is 130. This value means the engine cannot use a concept called memory grant feedback to avoid the spill. Change the value to 160. This should take a few seconds.
1. Run the query in **selectquery.sql** again. The sort warning is still there but also notice an index recommendation. The query still takes 1.5 mins to run. Memory grant feedback will now change the memory grant to be larger on the next execution.
1. Run the query again. This time it only takes about 20 seconds and the sort warning and spill are gone. However, the sort still exists and an index could be missing.
1. Load and execute the script **query_store_feedback.sql**. Notice that the memory grant feedback is persisted in the query store so it will always be used in the future for this plan.

## Analyze the performance of the workload after memory grant feedback was enabled.

1. With our workload test tool ostress we will get a different query signature so in order to get feedback run workload.cmd with the following parameters:

   `workload 1 2`
    
    This will take around 1 in 40 seconds to finish.

1. Now run workload.cmd with the following parameters:

    `workload 5 1`
 
    This will take only ~30 seconds minutes to complete which is an improvement from before memory grant feedback was enabled. 

1. So let's increase the workload by running workload.cmd with the following parameters:

    `workload 5 5`

    This will take around 2 mins and 30 seconds to complete.

1. **While** this is running, execute the **troubleshooting_query.sql** script again and you should now we see RESOURCE_SEMAPHORE waits. So we have avoided the spills but the grants are still large enough to cause waits because of the large sort.

## Resolve the large memory grant issue that remains

1. We saw there is a missing index so let's create it but slightly modify the suggestion to include both columns from the sort. Load and execute **create_index.sql** in SSMS.
1. Run **selectquery.sql** in SSMS with the Actual Execution Plan enabled. This still takes around 13 seconds to finish. You can see from the query plan that the sort and scan are gone and an index seek is used.
1. Run workload.cmd with these parameters:

    `workload 5 5`

    It will take about 1 minute to run which is much faster than the execution before the index was created.

1. While this is running, execute **troubleshooting_query.sql** again. Notice no waits exist.
1. Look at the Compute Utilization in the Azure Portal and you can see while the overall duration is faster, resources have shifted to consume CPU utilization.

## Long-term solutions

1. If you look closer at **selectquery.sql** you will see the query is using this WHERE clause:

    `WHERE customer_date < GETDATE()`

    If you look at the results of the last execution and hover over the Index Seek operators you can see the result is ~1M rows. This means the engine is trying to seek almost the entire table and the WHERE clause is not very selective.
1. In addition, if you look at the table definition in **customer_ddl.sql** you will see one of the columns in our query is customer_type and it is defined as follows:

    `customer_type char(500) not null`

    Defining a column with type char and making it not null will require SQL to *pad* all values to the entire 500 characters making rows very large and requiring more pages to seek even for 1M rows. It is possible that even if the WHERE clause needed to get 1M rows, the query would run much faster if the column was defined as varchar(500).