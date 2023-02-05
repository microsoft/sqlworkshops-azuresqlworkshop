# Steps to troubleshooting a High CPU problem due to an anti-pattern query

Use the following steps to reproduce, monitor, and resolve a high CPU condition for an Azure SQL Database because of an anti-pattern query

## Setup

Setup the problem using the following steps:

1. Deploy an Azure SQL Database using the General Purpose Service Tier using the Provisioned Compute Tier with 2 vCores. Use the following resource to see a quick start on how to create an Azure SQL Database: <https://learn.microsoft.com/azure/azure-sql/database/single-database-create-quickstart>. I used the database name of **highcpu_antipattern**. You can use that name or if use your own you will need to edit scripts in this example to match your database name.
1. Edit the script **customer_ddl.sql** to put in your database name (if not highcpu_antipattern) for the ALTER DATABASE statement to clear the query store after table creation and data load.
1. Connect to Azure SQL Database with SQL Server Management Studio (SSMS) and run the script **customer_ddl.sql**. This script will create a table, populate data into the table, and create a stored procedure. It will take ~30 seconds to run this script. Use the following resource to see how to connect and run a query to Azure SQL Database with SSMS: <https://learn.microsoft.com/azure/azure-sql/database/connect-query-ssms?view=azuresql>
1. Edit the script **workload.cmd** and **workload_repeat.cmd** to put in your logical server, database name, admin user name, and admin password. These scripts use the **ostress.exe** tool.

## Reproduce the High CPU problem

**Note:** You can reproduce the problem immediately but if you wait for 60 minutes the metrics in the Azure Portal are "cleaner" as they will not show any resources from creating the table and loading data.

1. Run an example workload using the script **workload.cmd**. This command script executes the stored procedure several times using multiple concurrent users. It will take ~10-13mins for this to complete.
1. Using the Azure Portal for the Azure SQL Database select Overview in the resource menu on the left. Then select the Monitoring tab. Scroll down to view the Compute Utilization chart. Notice the CPU Percentage is at 100% for a sustained period of time.

## Analyze the problem

1. Connect to the database with SSMS.
1. In Object Explorer, expand the Query Store folder under the database. Run the Top Resource Consuming Queries report. Change the report to Avg CPU. You may see more than one "dot" but this is for the same query plan and the Average CPU is high in any of these cases.
1. The query with the highest average is from the stored procedure used for the workload.
1. Under the query is the query plan and the query text. The plan for this query using a Table Scan. This is surprising since you created an index in the **customer_ddl.sql** script.
1. Under the query is the query plan. The plan for this query using a Table Scan. Notice the warning over the SELECT because of a datatype conversion. This is because the query tries to compare an INT value with a NVARCHAR(10) column from the table. Even though these datatypes can be converted by the engine an index cannot be used in this situation.
1. Using the right pane hover over the dot and see the average duration is ~2 seconds.

## Solve the problem by fixing the stored procedure

1. Run the script **customer_proc_fix.sql** to alter the stored procedure to use the right data type.
1. Run the workload again by executing **workload.cmd**. This should now only take 1-2 seconds.
1. Go back into SSMS and refresh the Top Resource Consuming Queries report. See the new colored dot in the right pane. Hover over the new dot and notice the Avg duration is now < 1ms. Click the dot to see a new plan is now used using the Index.
1. Run the **workload_repeat.cmd** script to now run the workload with a larger number of executions (with the same number of concurrent users). This shows we can get consistent fast performance even over a longer period of time. 
1. Observe in the Query Store report that the average CPU for the query is the same even with ~500,000 executions.
1. In the Azure portal under Compute Utilization you can see a significantly lower amount of CPU usage than what existed without the index.