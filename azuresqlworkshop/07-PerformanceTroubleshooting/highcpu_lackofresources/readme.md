# Steps to troubleshooting a High CPU problem due to lack of resources

Use the following steps to reproduce, monitor, and resolve a high CPU condition for an Azure SQL Database because of a lack of resources.

## Setup

Setup the problem using the following steps:

1. Deploy an Azure SQL Database using the General Purpose Service Tier using the Provisioned Compute Tier with 2 vCores. Use the following resource to see a quick start on how to create an Azure SQL Database: <https://learn.microsoft.com/azure/azure-sql/database/single-database-create-quickstart>. I used the database name of **highcpu_lackofresources**. You can use that name or if use your own you will need to edit scripts in this example to match your database name.
1. Edit the script **customer_ddl.sql** to put in your database name (if not highcpu_lackofresources) for the ALTER DATABASE statements to clear the query store after table creation and data load.
1. Connect to Azure SQL Database with SQL Server Management Studio (SSMS) and run the script **customer_ddl.sql**. This script will create a table, populate data into the table, and create a stored procedure. It will take ~30 seconds to run this script. This script will also create indexes for both the tabkey and customer_id column so that the queries will use indexes to run fast. Use the following resource to see how to connect and run a query to Azure SQL Database with SSMS: <https://learn.microsoft.com/azure/azure-sql/database/connect-query-ssms?view=azuresql>
1. Edit the script **workload.cmd** and **workload_scale.cmd** to put in your logical server, database name, admin user name, and admin password. These scripts use the **ostress.exe** tool.

## Reproduce the High CPU problem

**Note:** You can reproduce the problem immediately but if you wait for 60 minutes the metrics in the Azure Portal are "cleaner" as they will not show any resources from creating the table and loading data.

1. Run **workload.cmd first**. This should only take a minute.
1. Pause for 10 mins. This allows you to see the problem clearly in the Azure Portal.
1. Run an example workload at scale using the script **workload_scale.cmd**. This command script executes the stored procedure several times using multiple concurrent users. It will take ~5-6mins for this to complete.

## Analyze the problem

1. Using the Azure Portal for the Azure SQL Database select Overview in the resource menu on the left. Then select the Monitoring tab. Scroll down to view the Compute Utilization chart. Change from Max to Average. Notice the CPU percentage was not very big but later went to 100%. During the 100% Workers percentage was higher.
1. Connect to the database with SSMS
1. In Object Explorer, expand the Query Store folder under the database. Run the Top Resource Consuming Queries report. You see the query is using an index but has two different "dots" to show total duration. One is much higher with a larger number of executions. So we had an increase in overall executions but a much higher CPU %.
1. Now look at the Query Wait Statistics. It shows waits on CPU. If you double-click this the query that waits the most on CPU is our query. This along with the Workers percentage seen in the Azure portal means that we may not have enough CPU resources to satisfy the needs of the workload.
1. Got back to the Azure portal. Click anywhere in the Compute Utilization chart. A new screen comes up with more detailed metrics. At the top right click where it says Local Time 24 hours... Change the time for tha last one hour. Change Time Granularity to 1 minute. Select Apply. You can now see more details on the CPU utilization between the two timeframes.
1. On left hand side click on Add Metric. Select Session Count.
1. You can see that when CPU rose to 100% there was a huge increase in sessions to the database. This translates to a huge increase in workload but because there is not enough CPU resources the workload takes longer now to complete. Leave this chart as is so you can see the difference later.

## Solve the problem by increasing resources for the database

1. Use the Azure Portal in the Overview screen to select the Pricing Tier. User the slider to increase the number of vCores to 20 thus increases vCores by 10x. This should only take a few minutes. Wait for the progress to say it has completed.
1. Run **workload_scale.cmd** again.
1. Now the workload runs in less than a minute (~50 seconds). You will also see much less CPU resources used for a shorter duration when looking at metrics in the portal and a reduction in workers usage.
1. You could also use the Serverless compute tier and put a scale of 2 to 20 to autoscale to fit the needs of a varying workload requirements.