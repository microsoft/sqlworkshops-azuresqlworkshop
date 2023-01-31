# Steps to troubleshooting a High CPU problem because of a lack of resources

Use the following steps to reproduce, monitor, and resolve a high CPU condition for an Azure SQL Database because of a lack of resoures

## Setup

Setup the problem using the following steps:

1. Deploy an Azure SQL Database using the General Purpose Service Tier using the Provisioned Compute Tier with 2 vCores
2. Connect to Azure SQL Database using a tool like SSMS or Azure Data Studio and run the script customer_ddl.sql. This script will create a table, populate data into the table, and create stored procedure(s). It will take ~30 seconds to run this script. This script will also create indexes for both the tabkey and customer_id column so that the queries will use indexes to run fast.
3. Install the tool ostress.exe from https://aka.ms/ostress.exe.
4. Edit the script workload.cmd and workload_scale.cmd to put in your logical server, database name, admin user name, and admin password.

## Reproduce the High CPU problem

Note: You will see more of a clear picture of high CPU if you wait for one hour AFTER creating the database and table with data to reproduce the problem.

5. Run workload.cmd first. This should only take a minute.
6. Pause for 10 mins.
7. Run an example workload at scale using the script workload_scale.cmd. This command script executes the stored procedure several times using multiple concurrent users. It will take ~5-6mins for this to complete.

## Analyze the problem

8. Using the Azure Portal for the Azure SQL Database select Overview in the resource menu on the left. Then select the Monitoring tab. Scroll down to view the Compute Utiliation chart. Change from Max to Average. Notice the CPU percentage was not very big but later went to 100%. During the 100% there Workers percentage was higher.
9. Connect to the database with SSMS
10. In Object Explorer, expand the Query Store folder under the database. Run the Top Resource Consuming Queries report. You see the query is using an index but has two different "dots" to show total duration. One is much higher with a larger number of executions. So we had an increase in overall executions but a much higher CPU %.
11. Now look at the Query Wait Statistics. It shows waits on CPU. If you double-click this the query that waits the most on CPU is our query. This means that we may not have enough CPU resources to satisfy the needs of the workload.
12. Got back to the Azure portal. Click anywhere in the compute utilization chart. A new screen comes up with more detailed metrics. At the top right click where it says Local Time 24 hours... Change the time for tha last 30 minutes. Change Time Granularity to 1 minute. Select Apply. You can now see more details on the CPU utilization between the two timeframes.
13. On left hand side click on Add Metric. Select Session Count.
14. You can see that when CPU rose to 100% there was a huge increase in sessions to the database. This translates to a huge increase in workload but because there is not enough CPU resources the workload takes longer to now complete. Leave this chart as is so you can see the difference later.

## Solve the problem by increasing resources for the database

15. Use the portal to increase the number of vCores to 20 thus increases cores by 10x. This should only take a few minutes. Wait for the progress to say it has completed.
16. Run workload_scale.cmd again.
17. Now the workload runs in less than a minute (~50 seconds). You will also see much less CPU resources used for a shorter duration when looking at metrics in the portal and a reduction in workers usage.
18. You could also use the Serverless compute tier and put a scale of 2 to 16 to autoscale to fit the needs of a varying workload.