# Steps to troubleshooting a High CPU problem because of an anti-pattern query

Use the following steps to reproduce, monitor, and resolve a high CPU condition for an Azure SQL Database because of an anti-pattern query

## Setup

Setup the problem using the following steps:

1. Deploy an Azure SQL Database using the General Purpose Service Tier using the Provisioned Compute Tier with 2 vCores
2. Connect to Azure SQL Database using a tool like SSMS or Azure Data Studio and run the script customer_ddl.sql. This script will create a table, populate data into the table, and create a stored procedure. It will take ~30 seconds to run this script. This script will also create indexes for both the tabkey and customer_id column so that the queries will use indexes to run fast.
3. Run the script customer_proc.sql to create a new stored procedure to get customer information using the customer_id column.
4. Install the tool ostress.exe from https://aka.ms/ostress.exe.
5. Edit the script to put in your logical server, database name, admin user name, and admin password.

## Reproduce the High CPU problem

6. Run an example workload of the new stored proceure using the script workload.cmd. This command script executes the stored procedure several times using multiple concurrent users. It will take ~10-13mins for this to complete.
7. Using the Azure Portal for the Azure SQL Database select Overview in the resource menu on the left. Then select the Monitoring tab. Scroll down to view the Compute Utiliation chart. Notice the CPU Percentage is at 100% for a sustained period of time.

## Analyze the problem

8. Connect to the database with SSMS
9. In Object Explorer, expand the Query Store folder under the database. Run the Top Resource Consuming Queries report.
10. The query with the higest duration is from the new stored procedure used for the workload. This may be surprising since there is an index for both the tabkey and customer_id columns.
11. Under the query is the query plan. The plan for this query using a Table Scan. Notice the warning over the SELECT because of a datatype conversion. This is because the query tries to compare an INT value with a NVARCHAR(10) column from the table. Even though these datatypes can be converted by the engine an index cannot be used in this situation.
12. Using the right pane hover over the dot and see the average duration is ~2 seconds.

## Solve the problem by changing the stored procedure to use a NVARCHAR(10) type for the parameter.

13. Run the script customer_proc_fix.sql to alter the stored procedure to use the right data type.
14. Run the workload again by executing workload.cmd. This should now only take 1-2 seconds.
15. Go back into SSMS and refresh the Top Resource Consuming Queries report. The new procedure is the next query (the bar is very small because it ran so fast). If you change the view to a grid you can see the second query in the list is the query and stored procedure but it is considereda "new" query because it uses a different paraemter type. Notice it uses an index. If you hover over the dot for the plan you can see the average duration is < ms.