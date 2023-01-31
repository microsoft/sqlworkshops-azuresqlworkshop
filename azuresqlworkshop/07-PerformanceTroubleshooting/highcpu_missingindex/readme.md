# Steps to troubleshooting a High CPU problem becaue of a missing indexes in Azure SQL Database

Use the following steps to reproduce, monitor, and resolve a high CPU condition for an Azure SQL Database because of a missing index for a SQL query

## Setup

Setup the problem using the following steps:

1. Deploy an Azure SQL Database using the General Purpose Service Tier using the Provisioned Compute Tier with 2 vCores
2. Connect to Azure SQL Database using a tool like SSMS or Azure Data Studio and run the script customer_ddl.sql. This script will create a table, populate data into the table, and create a stored procedure. It will take ~30 seconds to run this script.
3. Install the tool ostress.exe from https://aka.ms/ostress.exe.
4. Edit the script to put in your logical server, database name, admin user name, and admin password.

## Reproduce the High CPU problem

Note: You can reproduce the problem immediately but if you wait for 60 minutes the metrics in the Azure Portal are "cleaner" as they will not show any resources from creating the table and loading data.

5. Run an example workload of the stored proceure using the script workload.cmd. This command script executes the stored procedure several times using multiple concurrent users. It will take ~10-13mins for this to complete.
6. Using the Azure Portal for the Azure SQL Database select Overview in the resource menu on the left. Then select the Monitoring tab. Scroll down to view the Compute Utiliation chart. Notice the CPU Percentage is at 100% for a sustained period of time.

## Analyze the problem

7. Connect to the database with SSMS
8. In Object Explorer, expand the Query Store folder under the database. Run the Top Resource Consuming Queries report. Change the report to Avg CPU. You may see more than one "dot" but this is for the same query plan and the Avergage CPU is high in any of these cases.
9. The query with the higest average from the stored procedure used for the workload.
10. Under the query is the query plan. The plan for this query using a Table Scan. Notice the warning for a missing index.

## Solve the problem by creating an index

11. Right click in the query plan pane and select Mising Index Details. This will bring up a query window with T-SQL to create an index.
12. Use the script create_index.sql in SSMS to create the missing index but also create it with the new ONLINE and RESUMABLE options.
13. Run the workload again by executing workload.cmd. This should now only take 1-2 seconds.
14. Go back into SSMS and refresh the Top Resource Consuming Queries report. See the new colorded dot in the right pane. Hover over the new dot and notice the Avg duration is now < 1ms. Click the dot to see a new plan is now used using the Index.
15. Confirm in the Azure portal no high CPU exists. The workload run so fast now there is no CPU to show.