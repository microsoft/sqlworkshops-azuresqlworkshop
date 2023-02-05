# Steps to troubleshoot a waiting problem due to blocking

Use the following steps to reproduce, monitor, and resolve a waiting problem due to blocking.

## Setup

Setup the problem using the following steps:

1. Deploy an Azure SQL Database using the General Purpose Service Tier using the Provisioned Compute Tier with 2 vCores choosing the Sample database (AdventureWorksLT) under Additional Settings. Use the following resource to see a quick start on how to create an Azure SQL Database: <https://learn.microsoft.com/azure/azure-sql/database/single-database-create-quickstart>. I used the database name of **waiting_blocking**. You can use that name or if use your own you will need to edit scripts in this example to match your database name.
1. Edit the scripts **insert.cmd**, **update.cmd**, and **delete.cmd** to put in your logical server, database name, admin user name, and admin password. These scripts use the **ostress.exe** tool.

## Reproduce the the blocking problem

1. Run the T-SQL batch in the script **select.sql** in SSMS. Use the following resource to learn how to connect to an Azure SQL Database from SSMS: <https://learn.microsoft.com/azure/azure-sql/database/connect-query-ssms?view=azuresql>.
1. Run the script **workload.cmd** which starts the insert.cmd, update.cmd, and delete.cmd scripts in 3 separate command windows.

## Analyze the problem

1. Using the Azure Portal for the Azure SQL Database, select Overview in the resource menu on the left. Then select the Monitoring tab. Scroll down to view the Compute Utilization chart. Notice the CPU % is very low. Pay close attention to the scale factor % on the left hand side since the visual chart may appear to show a high number.
1. In Object Explorer in SSMS, expand the Query Store folder under the database. Run the Top Resource Consuming Queries report. There is no query related to our workload that appears.
1. Now look at the Query Wait Statistics. Nothing there related to our workload.
1. It could be a blocking problem. Load the script **find_blocking.sql** in SSMS and execute it.
1. Look at the blocking_session_id. Notice that the session_id for this value is not actively running any queries but has an open transaction count = 1. This is the "lead blocker". The last column in the results show that the last query executed by this session started a transaction and ran a SELECT in an isolation level that holds locks. Note the session_id of the lead blocker as you will need that information to resolve the problem.

## Resolve the problem with immediate relief

1. Open a new query window in SSMS and execute the following T-SQL statement: **KILL <session_id>** which is the session_id for the lead blocker.
1. Run the query in **find_blocking.sql** again. Notice the blocking is gone.
1. Close the command windows that are open from running workload.cmd.