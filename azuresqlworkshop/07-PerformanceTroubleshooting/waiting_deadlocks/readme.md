# Steps to troubleshoot a waiting problem due to deadlocks

Use the following steps to reproduce, monitor, and resolve a waiting problem due to deadlocks.

## Setup

Setup the problem using the following steps:

1. Deploy an Azure SQL Database using the General Purpose Service Tier using the Provisioned Compute Tier with 2 vCores choosing the Sample database (AdventureWorksLT) under Additional Settings. Use the following resource to see a quick start on how to create an Azure SQL Database: <https://learn.microsoft.com/azure/azure-sql/database/single-database-create-quickstart>. I used the database name of **waiting_deadlocks**. You can use that name or if use your own you will need to edit scripts in this example to match your database name.
1. Edit the scripts **workload1.cmd** and **workload2.cmd** to put in your logical server, database name, admin user name, and admin password. These scripts use the **ostress.exe** tool.
1. If you have used a different database name than waiting_deadlocks, edit **kusto_deadlock.txt** to put in your database name.
1. In the Azure Portal for the database, add deadlocks to diagnostics for a Log Analytics workspace. Use the following resources to learn more how to add diagnostics for monitoring for an Azure SQL Database: <https://learn.microsoft.com/azure/azure-sql/database/monitoring-sql-database-azure-monitor>.

## Reproduce deadlocks

1. Run **workload.cmd**. This script runs **workload1.cmd** and **workload2.cmd**. Let the two windows that come up run for a few minutes before analyzing the problem.

## Analyze the problem

1. Using the Azure Portal for the Azure SQL Database, select Overview in the resource menu on the left. Then select the Monitoring tab. Scroll down to view the Compute Utilization chart. Notice the CPU % is very low. Pay close attention to the scale factor % on the left hand side since the visual chart may appear to show a high number.
1. In Object Explorer, expand the Query Store folder under the database. Run the Top Resource Consuming Queries report. There appear to be queries related to our problem with long durations but almost no CPU. Notice that in the right pane there is a triangle icon which if you hover over say that some query executions "Failed". So some of the queries are not completing due to an error.
1. If you look at Wait Statistics you will see there is some waiting on locks. So some are failing and some waiting on locks.
1. It could be a blocking problem. Load **find_blocking.sql** in SSMS and execute it. You may or may not see blocking but if you run this multiple times it is intermittent.
1. If you go back to the Azure Portal you can drill into the Compute Utilization chart to bring up Metrics. Add the Deadlocks metric. You can see that many deadlocks are occurring.
1. In order to get more details on these deadlocks, one method you can use is look at deadlocks from Azure Diagnostics using Kusto. Select Logs under Monitoring. Click the X to remove the query window. Copy the text from the file **kusto_deadlock.txt** into New Query Window and select Run.
1. The output is a series of rows of all the deadlocks that have occurred. Scroll to the right to see a column called **deadlock_xml_s**. If you hover over a cell this is a deadlock XML report.
1. You can then take the XML from the deadlock report, save it to an file with an extension of .xdl file, and then in SSMS open it to see a visual look of the deadlock. This visual shows two sessions trying to obtain locks in opposite order, a classic deadlock problem. An example file **deadlock.xdl** is provided.

## Resolve the problem

1. You could avoid future deadlocks in this scenario by changing the T-SQL statements in **sessionOne.sql** and **sessionTwo.sql** to update the tables in the same order. **Note:** The waitfor commands in the script are only to easily see a deadlock problem.