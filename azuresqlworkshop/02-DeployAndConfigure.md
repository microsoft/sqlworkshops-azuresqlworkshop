# Module 2 - Deploy and Configure

#### <i>The Azure SQL Workshop</i>

<p style="border-bottom: 1px solid lightgrey;"></p>

<img style="float: left; margin: 0px 15px 15px 0px;" src="https://github.com/microsoft/sqlworkshops/blob/master/graphics/textbubble.png?raw=true"> <h2>Overview</h2>

> You must complete the [prerequisites](../azuresqlworkshop/00-Prerequisites.md) before completing these activities. You can also choose to audit the materials if you cannot complete the prerequisites. If you were provided an environment to use for the workshop, then you **do not need** to complete the prerequisites.

In this module's activities, you will deploy and configure Azure SQL, specifically Azure SQL Database. In addition to the Azure portal, you'll leverage SSMS, Azure Data Studio (including SQL and PowerShell Notebooks), and the Azure CLI.

The in-class version of this workshop involves a short presentation, which you can review [here](../slides/AzureSQLWorkshop.pptx).

Throughout the activities, it's important to also read the accompanying text to the steps, but know that you can always come back to this page to review what you did at a later time (after the workshop).  

In this module, you'll cover these topics:  
[2.1](#2.1): Pre-deployment planning  
[2.2](#2.2): Deploy and verify  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Activity 1](#1): Deploy Azure SQL Database using the Azure portal   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Activity 2](#2): Initial connect and comparison  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Activity 3](#3): Verify deployment queries   
[2.3](#2.3): Configure  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(Bonus) [Activity 4](#4): Configure with Azure CLI  
[2.4](#2.4): Load data  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(Bonus) [Activity 5](#5): Load data  

<p style="border-bottom: 1px solid lightgrey;"></p>

<h2><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/pencil2.png"><a name="2.1">2.1 Pre-deployment planning</h2></a>

Before you start deploying things in Azure, it's important to understand what your requirements are and how they map to offerings in Azure SQL. Using what you learned in the Azure SQL introduction module, it's time to make a plan. You need to answer the following questions:

* Deployment method: Azure portal or command-line interfaces?
* Deployment option: VM, DB, Elastic Pool, MI, or Instance Pool?
* Purchasing model (Azure SQL Database only): DTU or vCore?
* Service tier (service-level objective): General purpose, business critical, or hyperscale?
* Hardware: Gen5, or something new?
* Sizing: number of vCores and data max size?  

> The Data Migration Assistant tool (DMA) has a [SKU Recommender](https://docs.microsoft.com/en-us/sql/dma/dma-sku-recommend-sql-db?view=sql-server-ver15) that can help you determine the number of vCores and size if you are migrating.  

In addition, and perhaps prior to answering the question above, you need to pick a workload that is either going to be migrated to Azure SQL or be "born in the cloud". If you are migrating, there are many tools and resources available to help you plan, assess, migrate, and optimize your database(s) and application. Resources are provided at the end of this module.  

### Resource limit considerations

Aside from limits, rates, and capabilities discussed in the Azure SQL introduction module (like IOPS or In-Memory OLTP), there are other resource limits, which are affected by your choice of Azure SQL Managed Instance, Azure SQL Database, or options within these choices:  

* Memory
* Max log size
* Transaction Log Rate
* Data IOPS
* Size of tempdb
* Transaction log rate
* Data IOPS
* Max concurrent workers
* Backup retention

The limits for Azure SQL Managed Instance and Azure SQL Database are dependent on your choice of purchasing model, service tier, and number of vCores (or DTU in Azure SQL Database only). Within a General Purpose Azure SQL Database, your choice of Provisioned or Serverless compute will also affect these limits. You should review what's included in what you plan to deploy, before deploying, to ensure you are starting out with what you may need.  

It is also important to know that Azure SQL resources have overall resource limits *per subscription* and *per region*. If you need to increase your limits, it is possible to request a quota increase in the Azure portal.

<br>

<p style="border-bottom: 1px solid lightgrey;"></p>

<h2><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/pencil2.png"><a name="2.2">2.2 Deploy and Verify</h2></a>

Once you've completed your pre-deployment planning, it's time to deploy and verify that deployment. In this stage, you'll deploy Azure SQL (using the Azure portal or command-line), determine network configuration and how to connect, and run some queries that verify your deployment configuration.  

### Key deployment implementation details

While Azure is taking care of the deployment for you, there are some deployment implementation details that you should be aware of. All of the services are built on the Azure backbone known as *Azure Service Fabric*.  Understanding the backend of how some of these services are deployed and scaled on Azure Service Fabric will help you understand various behaviors that you may see.

#### Azure SQL Managed Instance

Behind the scenes, for Azure SQL Managed Instance, Azure deploys a dedicated ring (sometimes referred to as a *virtual cluster*) for your service. This architecture helps in providing security and native virtual network support. However, because of this architecture, deployment and scaling operations can take longer. For example, when you scale up or down, Azure deploys a new virtual cluster for you and then seeds it with your data. You can think of every instance as running on a single virtual machine. Azure SQL Instance pools were introduced to help with the long deployment time, because you can pre-deploy a "pool" of dedicated resources, making deploying into a pool and scaling within a pool much faster (and with a higher packing density since we can deploy multiple instances within a single VM).  

#### Azure SQL Database

Azure SQL database is contained by a logical database server. In most cases an Azure SQL Database is hosted by a dedicated SQL Server Instance, however you do not have to worry about managing the instance. The logical database server is used so you have something to connect to, as well as for grouping and managing certain permissions and configurations together. Within each logical database server, there is a logical master database, which can provide instance-level diagnostics.

#### Azure SQL Database - Hyperscale

The Hyperscale tier within Azure SQL Database (not yet in Azure SQL Managed Instance) has a unique architecture for Azure SQL. The Azure SQL team rearchitected Hyperscale for the cloud, and this architecture includes a multi-layer caching system, which can help with both speed and scale. Scaling and other operations no longer become size of data related and can be completed in constant time (a matter of minutes). The use of remote storage also allows for snapshot backups. In a later module of the Azure SQL fundamentals learning path, you will learn more details related to the architecture and how it affects performance and availability. One callout to consider during the deployment phase is that once you move a database to the Hyperscale tier, it is not possible to "go back" to the General purpose or Business critical tiers.

#### Resource Governance

As you increase or decrease the resources in a service tier, the limits for dimensions such as CPU, storage, memory, and more may change up to a certain threshold. While there's a multi-faceted approach to governance in Azure SQL, primarily the following three technologies are leveraged to govern your usage of resources in Azure SQL:  

* Windows Job Objects allow a group of processes to be managed and governed as a unit. Job objects are used to govern the file virtual memory commit, working set caps, CPU affinity, and rate caps. You can leverage the DMV `sys.dm_os_job_object` to see the limits in place.
* Resource Governor is a SQL Server feature that helps users (and in this case Azure) govern resources including CPU, physical IO, memory, and more. Azure SQL Managed Instance also allows user-defined Resource Governor workload groups and pools.
* File Server Resource Manager (FSRM) is available in Windows Server and is used to govern file directory quotas which are used to manage max data sizes.

Finally, there have been additional implementations to govern transaction log rate built into the database engine for Azure, through *transaction log rate governance*. This process limits high ingestion rates for workloads such as `BULK INSERT`, `SELECT INTO`, and index builds, and they are tracked and enforced as the subsecond level. They currently scale within a service tier linearly.  

<br>

<p><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/point1.png"><a name="1"><b>Activity 1</a>: Deploy Azure SQL Database using the Azure portal</b></p>

In this activity, you'll deploy Azure SQL Database deployment using the Azure portal. Throughout this exercise, you'll also get to explore the various options that are available to you.

**Step 1 - Deployment options**  

> Note: If you are not already connected to your Azure VM, do that now. For instructions on how to do that, see [here](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/connect-logon). All of the exercises for the remainder of the workshop should be completed in your VM. If you want to make viewing the instructions easier, you might consider opening these instructions in a browser in you VM.

Navigate to https://portal.azure.com/ and log in with your account, if you are not already. In the top search bar, type **Azure SQL** and review what appears:

![](../graphics/search2.png)  

There are a lot of different items and categories here, but basically this is giving you filters for what you can search on. Let's break them down:
* **Services**: if you select Services, then you're able to see the existing resources (i.e. already deployed) that you have all together. For example, if you clicked Azure SQL, you would see all of your SQL VMs, Databases, Logical servers, Managed Instances, and pools.
* **Resources**: this searches based on existing resource names. For example, if you searched for "adventureworks" any resources with "adventureworks" in the name would return here.
* **Marketplace**: this allows you to deploy new resources from the marketplace. 
* **Documentation**: this searches docs.microsoft.com for relevant documentation
* **Resource groups**: this allows you to search based on resource group name.

Next, select **Azure SQL** under **Marketplace**. This will bring you to the Azure SQL create experience. Take a few moments to click around and explore.

![](../graphics/AzureSQLDeploymentOptions.gif)

Next, select **Single database** and click **Create**.

>**NOTE**: There are various methods to deploy a single Azure SQL Database. Our [Quickstart](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-single-database-get-started) shows options for the portal, Powershell, and Azure CLI.

**Step 2 - Database name**  

Select the subscription and resource group you created in the prerequisites (or were provided), then enter a database name **AdventureWorksID** where ID is the unique identifier you used in the prerequisites for your resource group, or the unique ID at the end of the Azure login you were provided (e.g. for `odl_user_160186@....com` the ID you will use for the entirety of the workshop is `160186`, and for this step your database name would be **AdventureWorks160186**).  

**Step 3 - Server**  

When you create an Azure SQL Managed Instance, supplying the server name is the same as in SQL Server. However, for databases and elastic pools, an Azure SQL Database server is required. This is a *logical* server that acts as a central administrative point for single or pooled database and includes logins, firewall rules, auditing rules, threat detection policies, and failover groups (more on these topics later). This logical server does not expose any instance-level access or features as with Azure SQL Managed Instance. For Azure SQL Database servers, the server name must be unique across all of Azure. You can read more on SQL Database servers [here](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-servers).  

Select **Create new** next to **Server** and provide the following information:  
* *Server name*: **aw-serverID** where ID is the same identifier you used for the database and resource group.  
* *Server admin login*: **cloudadmin**. This is the equivalent to a member of the sysadmin role in SQL Server. This account connects using SQL authentication (username and password) and only one of these accounts can exist. You can read more about Administrator accounts for Azure SQL Database [here](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-manage-logins#unrestricted-administrative-accounts).
* *Password*: A complex password that meets [strong password requirements](https://docs.microsoft.com/en-us/sql/relational-databases/security/strong-passwords). **TIP**: As you type in your password you are given hints as to the requirements. You are also asked to confirm your password.
* *Location*: Use the same location as your resource group.  

![](../graphics/newserver.png)  

> Note: If there are other checkboxes here, accept the defaults.

Then, select **OK**.

**Step 4 - Opt-in for elastic pools**

In Azure SQL DB, you then decide if you want this database to be a part of an Elastic Pool (new or existing). In Azure SQL Managed Instance, [creating an instance pool (public preview) currently requires a different flow](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-instance-pools-how-to#create-an-instance-pool) than the Azure SQL create experience in the Azure portal. For this activity, select **No**.  

**Step 5 - Purchasing model**  
>For more details on purchasing models and comparisons, refer to [Module 1](../azuresqlworkshop/01-IntroToAzureSQL.md).  

Next to **Compute + storage** select **Configure Database**.  The top bar, by default shows the different service tiers available in the vCore purchasing model.

For the purposes of this workshop, we'll focus on the vCore purchasing model (recommended), so there is no action in this step. You can optionally review the DTU model by selecting **Looking for basic, standard, premium?** and by [comparing vCores and DTUs in-depth here](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-purchase-models
).  

**Step 6 - Service tier**  
>For more details on service tiers and comparisons, refer to [Module 1](../azuresqlworkshop/01-IntroToAzureSQL.md).  

The next decision is choosing the service tier for performance and availability. Generally, we recommend you start with the General Purpose and adjust as needed. For the purposes of this workshop, be sure to select **General Purpose** here (should be the default).  

**Step 7 - Hardware**
>For more details on available hardware and comparisons, refer to [Module 1](../azuresqlworkshop/01-IntroToAzureSQL.md).  

For the workshop, you can leave the default hardware selection of **Gen5**, but you can select **Change configuration** to view the other options available (may vary by region).  

**Step 8 - Sizing**

One of the final steps is to determine how many vCores and the Data max size. For the workshop, select **2 vCores** and **32 GB Data max size**.  

Generally, if you're migrating, you should use a similar size as to what you use on-premises. You can also leverage tools, like the [Data Migration Assistant SKU Recommender](https://docs.microsoft.com/en-us/sql/dma/dma-sku-recommend-sql-db?view=sql-server-ver15) to estimate the vCore and Data max size based on your current workload.  

The Data max size is not necessarily the database size of your data today. It is the maximum amount of data space that can be allocated for your database. For more information about the difference between data space used, data space allocated, and data max size, refer to this [explanation in the documentation](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-file-space-management#understanding-types-of-storage-space-for-a-database). This will also help you understand the log space allocated, which scales with your data max size.  

Before you select **Apply**, confirm your selections look similar to those below (your resource group, Database name, and Server will be specific to your choices):  

![](../graphics/configuredb.png)

The **Basics** pane should now look similar to the image below:  

![](../graphics/basicspane.png)

**Step 9 - Networking**

Select **Next : Networking**.  

Choices for networking for Azure SQL Database and Azure SQL Managed Instance are different. When you deploy an Azure SQL Database, currently the default is **No access**.  

You can then choose to select Public endpoint or Private endpoint. In this workshop we'll use the public endpoint and set the **Allow Azure services and resources to access this server** option to yes, meaning that other Azure services (e.g. Azure Data Factory or an Azure Virtual Machine) can access the database if you configure it. You can also select **Add current client IP address** if you want to be able to connect from the IP address from the client computer you used to deploy Azure SQL Database, which you do. Make sure your settings match below:

![](../graphics/networkconnect2.png)


With Azure SQL Managed Instance, you deploy it inside an Azure virtual network and a subnet that is dedicated to managed instances. This enables you to have a completely secure, private IP address. Azure SQL Managed Instance provides the ability to connect an on-prem network to a managed instance, connect a managed instance to a linked server or other on-prem data store, and connect a managed instance to other resources. You can additionally enable a public endpoint so you can connect to managed instance from the Internet without a Virtual Private Network (VPN). This access is disabled by default.  

The principle of private endpoints through virtual network isolation is available for Azure SQL Database through a  **private link**, and you can learn more [here](https://docs.microsoft.com/en-us/azure/private-link/private-link-overview).

More information on connectivity for Azure SQL Database can be found [here](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-connectivity-architecture) and for Azure SQL Managed Instance [here](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-managed-instance-connectivity-architecture). There will also be more on this topic in upcoming sections/modules.  

For now, select **Next : Additional settings**.

**Step 10 - Data source**

In Azure SQL Database, upon deployment you have the option to select the AdventureWorksLT database as the sample in the Azure portal. In Azure SQL Managed Instance, however, you deploy the instance first, and then databases inside of it, so there is not an option to have the sample database upon deployment (similar to SQL Server). You can learn more about the AdventureWorks sample databases on [GitHub](https://github.com/Microsoft/sql-server-samples/releases/tag/adventureworks).

You can also deploy a blank database or create a database based the restore of a backup from a geo-replicated backup. You can learn more on this option from the [documentation](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-recovery-using-backups#geo-restore).

For this workshop, select **Sample**.  

**Step 11 - Database collations**

Since we're using the AdventureWorksLT sample, the **database collation is already set**. For a review of collations and how they apply in Azure SQL, continue reading, otherwise **you can skip to Step 12**.

Collations in SQL Server and Azure SQL tell the Database Engine how to treat certain characters and languages. A collation provides the sorting rules, case, and accent sensitivity properties for your data. When you're creating a new Azure SQL Database or Managed Instance, it's important to first take into account the locale requirements of the data you're working with, because the collation set will affect the characteristics of many operations in the database. In the SQL Server box product, the default collation is typically determined by the OS locale. In Azure SQL Managed Instance, you can set the server collation upon creation of the instance, and it cannot be changed later. The server collation sets the default for all of the databases in that instance of Azure SQL Managed Instance, but you can modify the collations on a database and column level. In Azure SQL Database, you cannot set the server collation, it is set at the default (and most common) collation of `SQL_Latin1_General_CP1_CI_AS`, but you can set the database collation. If we break that into chunks:  
* `SQL` means it is a SQL Server collation (as opposed to a Windows or Binary collation)  
* `Latin1_General` specifies the alphabet/language to use when sorting
* `CP1` references the code page used by the collation
* `CI` means it will be case insensitive, where `CS` is case sensitive
* `AS` means it will be accent sensitive, where `AI` is accent insensitive

There are other options available related to character widths, UTF-8, etc., and more details about what you can and can't do with Azure SQL [here](https://docs.microsoft.com/en-us/sql/relational-databases/collations/collation-and-unicode-support?view=sql-server-ver15).


**Step 12 - Opt-in for Azure Defender**

When you deploy Azure SQL Database in the portal, you are prompted if you'd like to enable Azure Defender on a free trial. Select **Start free trial**. After the free trial, it is billed according to the [Azure Security Center Standard Tier pricing](https://azure.microsoft.com/en-us/pricing/details/security-center/). If you choose to enable it, you get functionality related to identifying/mitigating potential database vulnerabilities and threat detection. You'll learn more about these capabilities in the next module (<a href="https://github.com/microsoft/sqlworkshops-azuresqlworkshop/blob/master/azuresqlworkshop/03-Security.md" target="_blank">03 - Security</a>). In Azure SQL Managed Instance, you can enable it on the instance after deployment.  

**Step 13 - Tags**

Select **Next : Tags**. 

Tags can be used to logically organize Azure resources across a subscription. For example, you can apply the name "Environment" and the value "Development" to this SQL database and Database server, but you might use the value "Production" for production resources. This can helpful for organizing resources for billing or management. You can read more [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources).

![](../graphics/tags.png)  

**Step 14 - Review and create**

Finally, select **Next : Review + create**. Here you can review your deployment selections and the [Azure marketplace terms](https://go.microsoft.com/fwlink/?linkid=2045624).  

> You also have the option to **Download a template for automation**. This workshop will not cover that method, but if you're interested, you can [learn more](https://docs.microsoft.com/en-us/azure/azure-resource-manager/).

Take time here to ensure all of your selections match the workshop instructions.

Finally, select **Create** to deploy the service.  

Soon after selecting Create, you will be redirected to a page that looks like this (below), and where you can monitor the status of your deployment. This deployment option and configuration typically takes less than five minutes to deploy. Some images of what you might see are below.  

> Note: While you're waiting, you can open SSMS. It takes a while to open for the first time, and you'll use it in the next activity.    

![](../graphics/deploymentunderway.png)

And some time later ...

![](../graphics/deploymentunderway2.png)

And finally...

![](../graphics/deploymentunderway3.png)

If, for whatever reason, you get lost from this page and the deployment has not completed, you can navigate to your resource group, and select **Deployments**. This will give you the various deployments, their status, and more information.  

![](../graphics/deploymentstatus.png)

Once your resource has deployment, review the **Overview** pane for the SQL database in the Azure portal and confirm that the Status is **Online**.  

<p><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/point1.png"><a name="2"><b>Activity 2</a>: Initial connect and comparison</b></p>

In this activity you will learn the basics of connecting to your deployed Azure SQL Database and compare that experience to connecting to SQL Server.

**Step 1 - Connect to SQL Server 2019**

Now that everything looks to be up and running in the Azure portal, let's switch to a familiar tool, SQL Server Management Studio (SSMS). Open SSMS and connect, using Windows Authentication, to the local instance of SQL Server 2019 that's running on your Azure VM (if you don't have this, please revisit the prerequisites).  

![](../graphics/localconnect.png)  

If you completed the prerequisites, expanding the databases and system databases folders should result in a view similar to the following.  

![](../graphics/localserver.png)   

**Step 2 - Connect to Azure SQL Database**  

Next, let's connect to your Azure SQL Database logical server and compare. First, select **Connect > Database Engine**.  

![](../graphics/dbengine.png)  

For server name, input the name of your Azure SQL Database logical server. You may need to refer to the Azure portal to get this, e.g. *aw-server0406.database.windows.net*.  

> **Tip: locating resources in the Azure portal**  
> If you're new to the portal, there are a few ways you can locate resources, and depending on who you talk to, they may use a different method. Here are a few options to get you started:  
> 1. In the search bar type the **resource name** and select it under "Resources". For example, in the below image I search for a SQL Database "adventureworks", and I can then select the one I'm using for the workshop.  
> ![](../graphics/awdb.png)  
> 2. If you select **Microsoft Azure** in the top left corner of the Azure portal, it will take you to "Home". From here, you can select **Resource groups** and then select your resource group.  
> ![](../graphics/azureservices.png)  
> This will bring you to a view of all the resources that you deploy in the resource group.  
> ![](../graphics/rg.png)
> You could alternatively select SQL Databases or Virtual machines, depending what you are looking for.   
> 3. Other options / more information can be found in the [Azure portal overview](https://docs.microsoft.com/en-us/azure/azure-portal/azure-portal-overview) documentation page.  

Change the authentication to **SQL Server Authentication**, and input the corresponding Server Admin Login and Password (the one you provided during deployment in Activity 1)

Check the **Remember password** box and select **Connect**.

![](../graphics/connectazsql.png)   

Expanding the databases and system databases should result in a view similar to the following.  

![](../graphics/azureserver.png)   

Spend a few minutes clicking around and exploring the differences, at first glance, between the Azure SQL Database logical server and SQL Server. You won't deploy an Azure SQL Managed Instance as part of this workshop, but the image below shows how Azure SQL Managed Instance would appear in SSMS.

![](../graphics/miserver.png)   

### Verify deployment

Once you've completed your deployment, it's time to verify that deployment. In this stage, typically you'll check the results in the Azure portal or Azure CLI, run some queries that verify your deployment configuration, and tweak as necessary.  

For Azure SQL Managed Instance and Azure SQL Database, the first thing you might do is check the status of the database or instance with the Azure portal or the Azure CLI. Next, you can review the deployment details and activity log to ensure there were no failures or active issues.

For Azure SQL Managed Instance, you then might check the ERRORLOG, which is a common thing to do in SQL Server on-premises or in an Azure VM. This capability is not available in Azure SQL Database.  

Finally, you would likely confirm your network is configured properly, obtain the server name, and connect in a tool like SQL Server Management Studio (SSMS) or Azure Data Studio (ADS). There are several queries you can run to better understand what you've deployed and verify it was deployed correctly:  

```sql
SELECT @@VERSION
SELECT * FROM sys.databases
SELECT * FROM sys.objects
SELECT * FROM sys.dm_os_schedulers
SELECT * FROM sys.dm_os_sys_info
SELECT * FROM sys.dm_os_process_memory --Not supported in Azure SQL Database
SELECT * FROM sys.dm_exec_requests
SELECT SERVERPROPERTY('EngineEdition')
SELECT * FROM sys.dm_user_db_resource_governance -- Only available in Azure SQL DB and MI
SELECT * FROM sys.dm_instance_resource_governance -- Only available in Azure SQL MI
SELECT * FROM sys.dm_os_job_object -- Only available in Azure SQL DB and MI
```

One query related to the OS process memory is not supported in Azure SQL Database, even though it might appear to work. This query isn't supported because with Azure SQL Database, some things related to the OS are abstracted away from you so you can focus on the database.

The last three queries are available only in Azure SQL Database and/or Azure SQL Managed Instance. The first, `sys.dm_user_db_resource_governance`, will return the configuration and capacity settings used by resource governance mechanisms in the current database or elastic pool. You can get similar information for an Azure SQL Managed Instance with the second, `sys.dm_instance_resource_governance`. The third, `sys.dm_os_job_object`, will return a single row that describes the configuration of the job object that manages the SQL Server process, as well as resource consumption statistics.

The next two exercises will go through all the details involved in deploying an Azure SQL Database or an Azure SQL Managed Instance, and you will leverage the sandbox environment to deploy Azure SQL Database. After deployment, you'll leverage various verification queries and pre-run SQL Notebooks in Azure Data Studio to compare SQL Database, SQL Managed Instance, and SQL Server 2019.  


<p><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/point1.png"><a name="3"><b>Activity 3</a>: Verify deployment queries</b></p>

Now that you've seen how Azure SQL appears in SSMS, let's explore a tool that may be new to you called Azure Data Studio (ADS). ADS is a source-open tool that provides a lightweight editor and other tools (including Notebooks which you'll see soon) for interacting with Azure Data Services (including SQL Server on-prem, Azure SQL, Azure Database for PostgreSQL, and more). Let's take a brief tour to get acquainted.  

**Step 1 - Open Azure Data Studio and Connect**  

Open Azure Data Studio (ADS). When opening for the first time, you'll first be prompted to make a connection.  

>**NOTE**: If you get prompted to enable preview features, select **Yes**.  

![](../graphics/adsconnect.png)  

Note that you can connect to your local instance of SQL Server 2019 here. Let's do that first. You can also supply a Server group and Name, if you want to group different connections together. For example, when you connect to SQL Server 2019, create new Server group called **SQL Server 2019**. Since you are on a local server use a Server of **.** and connect to SQL Server 2019 by selecting **Connect**.  

![](../graphics/adsconnectss.png)  

You'll then go to a page that contains the **Server Dashboard**. Select the **Connections** button (red square in below image) to view your Server groups and connections.

![](../graphics/serverdashboard2.png)  

Your results should be similar to what you saw in SSMS. Select the **New connection** button in the **Servers** bar.  

![](../graphics/newconnection.png)  

Now, connect to your Azure SQL Database logical server, just as you did in SSMS, but putting it in a new Server group called **Azure SQL Database**. Note you need to use Authentication type **SQL Login** and supply your Server Admin login name and password. Check **Remember Password** and select **Connect**.

![](../graphics/adsconnectdb.png)  

In your **Connections** tab, under **Servers**, you should now see both connections, and you should be able to expand the folders similar to SSMS.  

![](../graphics/adsservers.png)   

Finally, to run queries in ADS, it's very similar to SSMS. Right-click on a database or server name and select **New query**. For Azure SQL Database, since you are not really getting a full "server", **`USE [DatabaseName]`** is not supported to change the database context. You must either change the connection to specifically the database you want to run a query on or use the drop-down. Change to the context of your **AdventureWorksID** database by selecting the drop-down box next to "master" and run `SELECT @@VERSION`.  

![](../graphics/newqueryads2.png)

**Step 2 - Set up easy file access with ADS**  

Now that your connected, you might want an easy way to access scripts and Jupyter notebooks. A Jupyter notebook (often referred to just as "Notebooks") is a way of integrating runnable code with text. If you aren't familiar with Jupyter notebooks, you will be soon, and you can check out more details later in the [documentation](https://docs.microsoft.com/en-us/sql/big-data-cluster/notebooks-guidance?view=sql-server-ver15).  

First, in ADS, select **File > Open Folder**.  

![](../graphics/openfolder.png)  

Next, navigate to where the repository of all the workshop resources are. If you followed the prerequisites, the path should be similar to `C:\Users\<vm-username>\sqlworkshops-azuresqlworkshop`. Once you're there, select **Select Folder**.  

![](../graphics/foldernav.png)  

Next, select the **Explorer** icon from the left taskbar to navigate through the files in the workshop.  

![](../graphics/explorer.png)  

Throughout the workshop, you'll be instructed at various points to open a notebook (file ending in `.ipynb`), and you can access those from here directly.   

**Step 3 - Verify deployment queries**  

Once you've deployed an instance of SQL (be it Azure SQL or SQL Server), there are typically some queries you would run to verify your deployment. In Azure SQL, some of these queries vary from SQL Server. In this step, you'll see what and how things change from SQL Server, and what is new.   

For this step, you'll use the notebook **VerifyDeployment.ipynb** which is under `azuresqlworkshop\02-DeployAndConfigure\verifydeployment\VerifyDeployment.ipynb`. Navigate to that file in ADS to complete this activity, and then return here.  

<p style="border-bottom: 1px solid lightgrey;"></p>

<h2><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/pencil2.png"><a name="2.3">2.3 Configure</h2></a>

Now that you've verified your deployment was successful and you know what resources are available, there are some other configurations you may wish to do related to configuring your SQL Managed Instance, SQL Database, or databases within a SQL Managed Instance (these are called *managed databases*).

### Configure Azure SQL Managed Instance

For Azure SQL Managed Instance, since it is essentially a managed SQL Server, many configurations available in SQL Server apply here. For example, you can configure using sp_configure and certain global trace flags, and you have options available around tempdb, model, and master. You also have control over your network connectivity and configuration, which will be discussed shortly.

### Configure databases

For managed databases in Azure SQL Managed Instance and Azure SQL Databases, you have options available with the `ALTER DATABASE` command. There are `SET` options and you can select the dbcompat you want to be at (this can help in migrations). You can also use the `ALTER DATABASE` command to change the Edition or Service tier. In Azure SQL Database you don't have access to the file configuration underneath, but in Azure SQL Managed instance you can perform file maintenance. Similar to Azure SQL Managed Instance, you have options available for network connectivity, network configuration, and space management.

In Azure SQL Database specifically, "stale" page detection is enabled and the default server collation `SQL_Latin1_General_CP1_CI_AS` is always used. Additionally, the following are default options set to **ON**:  

* SNAPSHOT_ISOLATION_STATE
* READ_COMMITTED_SNAPSHOT
* FULL RECOVERY
* CHECKSUM
* QUERY_STORE
* TDE
* ACCERATED_DATABASE_RECOVERY

### Restricted configuration choices

If you're familiar with SQL Server, there are a few configurations that are restricted by the Azure SQL Managed Instance and Azure SQL Database service that may affect how you run various tasks. The restricted choices are:  

* Stopping or restarting servers
* Instant file initialization
* Locked pages in memory (we may configure Locked pages in some SLO deployments)
* FILESTREAM and Availability Groups (we use Availability Groups internally)
* Server collation (in MI you can select during deployment but not change)
* Startup parameters
* Error reporting and customer feedback
* `ALTER SERVER CONFIGURATION`
* ERRORLOG configuration
* "Mixed Mode" security is forced
* Logon audit is done through SQL Audit
* Server Proxy account is N/A

Azure SQL Managed Instance and Database are PaaS offerings so restricting these choices should not inhibit your ability to fully use a SQL Server managed service.

### Storage management

For Azure SQL Managed Instance, there is a possible maximum storage size allowed for the instance based on your chosen SLO. You choose a maximum storage for the instance up to this possible maximum size. If you reach the maximum storage, you might get Message 1105 for a managed database or Message 1133 for the instance.

The size of any new database will be based on the size of the model database, which is a 100 Mb data file and an 8 Mb log file, just like SQL Server. Also like SQL Server, the size of model is configurable. You have the ability to alter the size as well as the number of files, but you do not have control over the physical location of them, as Microsoft has commitments per your deployment choice on I/O performance. Additionally, since remote storage is used in the General Purpose service tier, performance can be affected by the data file and log file size.

For Azure SQL Database, there is a possible maximum size of database files based on your chosen SLO. You choose a **Data max size** up to this possible maximum size. **Maxsize** for database files (as defined by the sys.database_files.max_size column) can grow to Data max size. 

To understand this idea of Data max size versus Maxsize, let's consider an example where a 1 TB (Data max size) General purpose database is deployed. When you do this, however, your database only requires ~500 GB (not 1 TB). As your database grows and approaches the Data max size, the database file, Maxsize for database files will also grow up to the 1 TB level.

The transaction log is in addition to the data size and is included in what you pay for storage. It's truncated regularly due to automatic backups because Accelerated Database Recovery is on by default. The log's maximum size is always 30 percent of Data max size. For example, if Data max size is 1 TB, then the maximum transaction log size is 0.3 TB, and the total of Data max size and log size is 1.3 TB.

The Azure SQL Database Hyperscale tier is different from the other service tiers in that it creates a database initially 40GB and grows automatically in size to the limit of 100TB. The transaction log has a fixed size restriction of 1TB.  

### Connectivity architecture and policy

Part of configuring your Azure SQL database logical server or Azure SQL Managed Instance involves determining the route of connection to your database(s).

For Azure SQL Managed Instance you can choose the connection type or policy during the deployment. In Azure SQL Database, you can choose the connection type after deployment.

You can keep the default of *Proxy for connections from outside and Redirect for connections within Azure* or configure something else.

:::image type="content" source="../graphics/5-connectivity.png" alt-text="Connection policies in Azure SQL" border="false":::

At the highest level, in Proxy mode, all connections are proxied through the a gateway. In Redirect mode, after the connection is established leveraging the gateway (redirect-find-db in the figure above) the connection can then connect directly to the database or managed instance.

The direct connection (redirect) allows for reduced latency and improved throughput, but also requires opening up additional ports to allow inbound and outbound communication in the range of 11000 - 11999.  

In the next exercise, you'll be exposed to some commands for configuring Azure SQL with the Azure CLI, and then you'll dive into evaluating the Proxy and Redirect connection policies.

<br>

<p><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/point1.png"><b>(Bonus) <a name="4">Activity 4</a>: Configure with Azure CLI</b></p>

So you've seen the Azure portal, SSMS, and SQL Notebooks in ADS, but there are other tools available to you to use to manage Azure SQL. Two of the most popular are the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest) and [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure). They are similar in their functionality, but for this activity we will focus on the Azure CLI.  

To complete this activity, you'll use a PowerShell notebook, which is the same concept as a SQL notebook, but the coding language is PowerShell. You can use PowerShell notebooks to leverage Azure CLI or Azure PowerShell, but we will focus on Azure CLI. For more information on the Azure PowerShell module, [see the documentation](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-powershell-samples?tabs=single-database). For both of these tools, you can also use the [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview), which is an interactive shell environment that you can use through your browser in the Azure portal.  

In the example that follows, you'll also explore the latency effects of using different connection policies in Azure SQL.  

For this activity, you'll use the notebook called **AzureCli.ipynb** which is under `azuresqlworkshop\02-DeployAndConfigure\cli\AzureCli.ipynb`. Navigate to that file in ADS to complete this activity, and then return here.  


<br>

<p style="border-bottom: 1px solid lightgrey;"></p>

<h2><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/pencil2.png"><a name="2.4">2.4 Load data</h2></a>

Once a database or instance is deployed, verified, and configured, the next logical step is to bring data in.There are many options available for you when it comes to loading data into Azure SQL. Many of them overlap with what's available on-premises, but there are a few that will be called out in this unit.  

### Bulk copy program

Bulk copy program (bcp) is a very common utility for connecting to Azure SQL from on-premises, as well as connecting to Azure SQL from an Azure Virtual Machine. You can then use it to move data into Azure SQL.  

### BULK INSERT

Bulk insert operations are very similar to in SQL Server on-premises, except instead of loading data from a file (or multiple files) on your machine, you load data from Azure Blob storage. The next exercise will walk through an example of how.  

### SSIS packages

In Azure SQL, you can use this to connect with SSIS on-premises. You can host an SSIS DB in Azure SQL Database or Azure SQL Managed Instance. Additionally, you can use the Azure-SSIS Integration Runtime (IR) for SSIS packages with tools like Azure Data Factory.

### Other options

Some other interesting options include using technologies like Spark or Azure Data Factory to load data into Azure SQL Database or Azure SQL Managed Instance. Not directly related to "loading", but it is possible to create a database leveraging an existing database for a copy or doing an import of a bacpac file. In Azure SQL Managed Instance, the T-SQL commands to restore a database natively from a URL is possible.  

### Considerations for loading data

The biggest difference between loading data on-premises and loading data into Azure SQL is that the data you want to load needs to be hosted in Azure as opposed to in files on-premises. These files and file systems on-premises can be stored in Azure Blob storage as an alternative. This will also increase the efficiency at which you can load your files in and set up ETL jobs.  

Another thing to keep in mind is that minimal logging is not supported, so you're always running in full recovery mode. Because of this and limits around log throughput, you might be affected by log governance as you're loading data. Techniques like using batches and appropriately sizing them become important during a bulk load. You'll see more of this in the following exercise. Loading into a clustered columnstore index may help in avoiding transaction log limits, depending on your scenario.

<br>

<p><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/point1.png"><b>(Bonus) <a name="5">Activity 5</a>: Load data into Azure SQL Database</b></p>

In this activity, you'll explore one scenario for bulk loading data from Azure Blob storage using T-SQL and Shared Access Signatures (SAS) into Azure SQL Database.   

For this activity, you'll use the notebook called **LoadData.ipynb** which is under `azuresqlworkshop\02-DeployAndConfigure\loaddata\LoadData.ipynb`. Navigate to that file in ADS to complete this activity, and then return here.  

In this module and throughout the activities, you learned how to deploy and configure Azure SQL. In the next module, you'll dive into security for Azure SQL.  

<p style="border-bottom: 1px solid lightgrey;"></p>

<p><img style="margin: 0px 15px 15px 0px;" src="../graphics/owl.png"><b>For Further Study</b></p>
<ul>
    <li><a href="https://docs.microsoft.com/en-us/sql/dma/dma-sku-recommend-sql-db?view=sql-server-ver15" target="_blank">Data Migration Assistant tool (DMA) SKU Recommender</a></li>
    <li><a href="https://docs.microsoft.com/en-us/azure/sql-database/sql-database-managed-instance-get-started" target="_blank">Quickstart: Create an Azure SQL Managed Instance</a></li>
    <li><a href="https://docs.microsoft.com/en-us/azure/sql-database/sql-database-managed-instance-migrate" target="_blank">How to migrate to Azure SQL Managed Instance</a></li>
</ul>


<p><img style="float: left; margin: 0px 15px 15px 0px;" src="https://github.com/microsoft/sqlworkshops/blob/master/graphics/geopin.png?raw=true"><b >Next Steps</b></p>

Next, Continue to <a href="https://github.com/microsoft/sqlworkshops-azuresqlworkshop/blob/master/azuresqlworkshop/03-Security.md" target="_blank"><i> 03 - Security</i></a>.
