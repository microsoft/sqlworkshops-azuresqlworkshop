# Steps to troubleshooting a performance problem due to waiting because of blocking

Use the following steps to reproduce, monitor, and resolve a performance problem that is waiting due to blocking

## Setup

Setup the problem using the following steps:

1. Deploy an Azure SQL Database using the General Purpose Service Tier using the Provisioned Compute Tier with 2 vCores chosing the sample database AdventureWorksLT
2. Install the tool ostress.exe from https://aka.ms/ostress.exe.
3. Edit the scripts insert.cmd, update.cmd, and delete.cmd to put in your logical server, database name, admin user name, and admin password.

## Reproduce the the blocking problem

4. Run select.sql first in SSMS
5. Now run workload.cmd

## Analyze the problem

6. Using the Azure Portal for the Azure SQL Database select Overview in the resource menu on the left. Then select the Monitoring tab. Scroll down to view the Compute Utiliation chart. Notice the CPU % is very low. Pay close attention to the scale factor of % on the left hand side.
7. In Object Explorer, expand the Query Store folder under the database. Run the Top Resource Consuming Queries report. There is no query related to our workload that appears.
8. Now look at the Query Wait Statistics. Nothing there related to our application.
9. It could be a blocking problem. Load find_blocking.sql and execute it.
10. Look at the blocking_session_id. Notice that the session_id for this value is not actively running any queries but has an open transcation count = 1. This is the "lead blocker". The last column in the results show that the last query by this session started a transaction and run a SELECT in an isolation level that holds locks.

## Resolve the problem with immediate relief

11. Open a new query windows and execute this query: KILL <session_id> which is the session_id for the lead blocker.
12. Run the query in find_blocking.sql again. Notice the blocking gone.
13. Close the command windows that are open from running workload.cmd
