# Steps to troubleshooting a performance problem due to waiting because of deadlocks

Use the following steps to reproduce, monitor, and resolve a performance problem that is waiting due to deadlocks

## Setup

Setup the problem using the following steps:

1. Deploy an Azure SQL Database using the General Purpose Service Tier using the Provisioned Compute Tier with 2 vCores chosing the sample database AdventureWorksLT
2. Install the tool ostress.exe from https://aka.ms/ostress.exe.
3. Edit the scripts workload1.cmd and workload2.cmd to put in your logical server, database name, admin user name, and admin password.

## Reproduce deadlocks

4. Now run workload.cmd. Let the two windows that come up run for around a few minutes before analyzing the problem.

## Analyze the problem

6. Using the Azure Portal for the Azure SQL Database select Overview in the resource menu on the left. Then select the Monitoring tab. Scroll down to view the Compute Utiliation chart. Notice the CPU % is very low. Pay close attention to the scale factor of % on the left hand side.
7. In Object Explorer, expand the Query Store folder under the database. Run the Top Resource Consuming Queries report. There appear to be queries related to our problem with long durations. Notice that in the right plan there is a triangle which if you hover over say that some "Failed". So some of our queries are not completing due to an error.
8. If you look at Wait Statistics you will see there is waiting on locks. So some are failing and some waiting on locks.
9. It could be a blocking problem. Load find_blocking.sql and execute it. You may or may not see blocking but if you run this multiple times it is intermittent.
10. If you go back to the Azure Portal you can drill into Metrics and add a deadlocks counter. You can see that many deadlocks are occurring.
11. In order to get more details on these deadlocks, one method you can use is look at deadlocks from Azure Diagnostics using Kusto.
12. You can then take the XML from the deadlock report, save it to an .xdl file, and then in SSMS open it as a visual look at a deadlock. This visual shows two sessions trying to obtain locks in opposite order, a classic deadlock problem.

## Resolve the problem

13. Don't change data from tables in opposite order.
14. There are other scenarios for deadlocks that can be solved through tuning, index design, etc.
