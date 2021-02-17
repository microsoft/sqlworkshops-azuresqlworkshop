![](../graphics/microsoftlogo.png)

# The Azure SQL Workshop

#### <i>A Microsoft workshop from the SQL team</i>

<p style="border-bottom: 1px solid lightgrey;"></p>

<img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/textbubble.png"> <h2>05 - Availability</h2>

> You must complete the [prerequisites](../azuresqlworkshop/00-Prerequisites.md) before completing these activities. You can also choose to audit the materials if you cannot complete the prerequisites. If you were provided an environment to use for the workshop, then you **do not need** to complete the prerequisites.   

Depending on the SLA, RTO, and RPO your business requires, Azure SQL has the options you need and built-in capabilities. In this module, you will learn how to translate your knowledge of backup/restore, Always On Failover cluster instances, and Always On Availability Groups to the options for business continuity in Azure SQL.


In this module, you'll cover these topics:  
[5.1](#5.1): Backup and restore   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(Bonus) [Activity 1](#1): Restore to a point in time  
[5.2](#5.2): Azure SQL high availability basics     
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Activity 2](#2): Basic HA in Azure SQL Database    
[5.3](#5.3): Business critical  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Activity 3](#3): Turn-key AGs in Business critical  
[5.4](#5.4): Higher availability  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Activity 4](#4): Geo-distributed auto-failover groups with read-scale in Business critical  
[5.5](#5.5): Availability and consistency  
[5.6](#5.6): Configuring and monitoring  

<p style="border-bottom: 1px solid lightgrey;"></p>

<h2><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/pencil2.png"><a name="5.1">5.1 Backup and restore</h2></a>

In all organizations, big or small, accidents can happen. That's why you always have to have a plan for how you will restore to where you need to be. In SQL Server, ideally, you want choose to restore to a point in time, but you can only do that if you are running in full recovery model. Under the bulk-logged recovery model, it's more likely that you'll have to recover the database to the end of the transaction log backup.

One of the benefits of Azure SQL is that Azure can take care of all of this for you. Since Azure SQL manages your backups and runs in full recovery model, it can restore you to any point in time (you can even restore a deleted database). We also automatically encrypt your backups if you enable TDE on the logical server or instance.

By default, a full database backup is taken once a week. Log backups are taken every 5-10 minutes, and differential backups every 12 hours. The backup files are stored in Azure Storage in read-access geo-redundant storage (RA-GRS) by default. However, you can choose to alternatively have your backups in zone-redundant storage (ZRS) or locally-redundant storage (LRS) which will be discussed later in the module. On an ongoing basis, the Azure SQL engineering team automatically tests the restore of automated backups of databases placed in logical servers and elastic database pools. For migrations to Azure SQL Managed Instance, an automatic initial backup with checksum of databases restored with the native RESTORE command or the Azure Database Migration Service occurs. And in Azure SQL Managed Instance, you can optionally take a native copy-only backup and store it in Azure Blob storage.

## Creating a backup strategy with Azure SQL Managed Instance and Azure SQL Database

Even though Azure SQL takes care of the heavy lifting for you, it's still important to understand how the backups are stored and processed and what your options for retention and restoring are. Ultimately, you're still responsible for the overall strategy when it comes to point in time restore, long term retention, and geo-restore.

### Point in Time Restore (PITR)

In Azure SQL Database and Azure SQL Managed Instance, you have the opportunity to conduct a self-service restore. You can select the exact point in time that you would like to restore and initiate it using the Azure portal, PowerShell/Azure CLI, or REST APIs. This point in time restore (PITR) will create a new database (different name) in the same logical server. If you need to replace the original database with the PITR database, you will have to rename both the original and the new database to get back to a working condition. In this way, no updates to connection strings will be needed.  

As far as retention for PITR goes, it varies between 1 and 35 days. By default, the retention period (for all service tiers and deployment options) is 7 days. In most deployment options and service tiers, you can configure this to be 1 to 35 days, depending on your scenario's requirements. For example, for a test database you may only need 1 day, but for a mission critical database, you may select the max of 35 days.

### Long term retention (LTR)

If 35 days is not enough to meet your organization's needs or compliance, you can opt for long term retention (LTR). This capability enables you to automatically create full database backups that are stored in RA-GRS, ZRS, or LRS storage for up to 10 years. For Azure SQL Database, LTR is generally available, and for Azure SQL Managed Instance, LTR is available in a limited public preview.

### Geo-restore

If there's a catastrophic event, your organization needs to be able to recover. Your backups are automatically stored in RA-GRS (unless you opt for ZRS or LRS) meaning your backups will be stored in the paired region. So if an entire region goes down and your databases or managed instances are in that region, you're protected. You can do a geo-restore to any other region from the most recent geo-replicated backup. This backup can be a bit behind the primary because it takes time to replicate the Azure blob to another region. You can easily perform a geo-restore by using the Azure portal, the PowerShell/Azure CLI, or REST APIs.

<br>

<p><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/point1.png"><a name="1"><b>(Bonus) Activity 1</a>: Undo errors to a point in time</b></p>

> Note: This is the first activity, but since restoring a database can take time, for the instructor-led version of this workshop, this will be a bonus activity to review or complete. If you are performing this in a self-study fashion, it is still recommended to review or complete the activity.  

In this activity, you'll see how a common error can be recovered using point in time restore (PITR). This is easy to do in the portal or programmatically, but in this activity you'll see how to do it with the Azure CLI.  

> Note: In this activity, you will use auditing in Log Analytics to determine the time of a dropped table done by accident. Auditing and Log Analytics were configured in Module 3, so be sure you have completed that before attempting this activity.

<p><img style="margin: 0px 15px 15px 0px;" src="../graphics/checkmark.png"><b>Steps</b></p>

For this activity, you'll use the notebook called **pitr.ipynb** which is under `azuresqlworkshop\05-Availability\pitr\pitr.ipynb`. Navigate to that file in ADS to complete this activity, and then return here.   

> Hint: To navigate to the folder you opened in Module 2 in ADS, you can select the **Explorer** button on the left-hand taskbar.  
> ![](../graphics/explorer.png)  
> If you don't see this view, you can open **in a new tab** [Activity 3, Step 2 in Module 2](https://github.com/microsoft/sqlworkshops-azuresqlworkshop/blob/master/azuresqlworkshop/02-DeployAndConfigure.md#3) and repeat the open folder exercise.   

<p style="border-bottom: 1px solid lightgrey;"></p>

<h2><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/pencil2.png"><a name="5.2">5.2 Azure SQL high availability basics</h2></a>

A critical piece of understanding the availability options and capabilities in Azure SQL include the service tier. The service tier you select will determine the underlying architecture of the database or managed instance that you deploy. 

While there are two purchasing models to consider, DTU and vCore, this unit will focus on the vCore service tiers and their architectures for high availability. However, in the DTU model, you can equate Basic and Standard tiers to General purpose, and Premium tiers to Business critical.  

### General purpose

Databases and managed instances in the General purpose service tier have the same availability architecture. Leveraging the figure below as a guide, first consider the *Application* and *Control Ring*. The application will connect to the server name which will then go off to a Gateway (GW) pointing the application to the server to connect to running on a VM. With General purpose, the primary replica leverages locally-attached SSD for tempdb, and the data and log files are stored in Azure premium storage, which is locally redundant storage (multiple copies in one region). The backup files are then stored in Azure standard storage which is considered RA-GRS, meaning it is globally redundant storage (copies in multiple regions).

As discussed in an earlier module in the learning path, all of Azure SQL is built on Azure Service Fabric, which serves as the Azure backbone. If Azure Service Fabric determines that a failover needs to occur, the failover will be similar to that of a Failover Cluster Instance (FCI) where the service fabric will look for a node with spare capacity and spin up a new SQL Server instance. Then, the database files will be attached, recovery will be run, and gateways are updated to point applications to the new node. Note that there is no virtual network or listener or updates required, this just comes built-in.

:::image type="content" source="../graphics/4-general-purpose-architecture.png" alt-text="General purpose architecture":::

### Business critical

The next service tier to consider is Business critical, which can generally achieve the highest performance and availability of all Azure SQL service tiers (General purpose, Hyperscale, Business critical). Business critical is meant for mission-critical applications that need low latency and minimal downtime.  

:::image type="content" source="../graphics/4-business-critical-architecture.png" alt-text="Business critical architecture":::

Business critical is very similar to deploying an Always on Availability Group (AG) behind the scenes. Unlike the General purpose tier, in Business critical the data and log files are all running on directly attached SSDs, which reduces network latency significantly (General purpose uses remote storage). In this AG, there are three secondary replicas, and one of them can be used as a read-only endpoint (at no additional charge). A transaction can complete a commit when at least one of the secondary replicas has hardened the change for its transaction log.

Read scale-out with one of the secondary replicas supports session-level consistency. That means if the read-only session reconnects after a connection error caused by replica unavailability, it may be redirected to a replica that is not 100% up-to-date with the read-write replica. Likewise, if an application writes data using a read-write session and immediately reads it using a read-only session, it is possible that the latest updates are not immediately visible on the replica. The latency is caused by an asynchronous transaction log redo operation.

If any type of failure occurs and the service fabric decides a failover needs to occur, failing over to a secondary replica is very fast, because it already exists and has the data attached to it. In a failover, you don't need a listener. The gateway will redirect your connection to the primary even after a failover. This switch happens quickly and then the service fabric takes care of spinning up another secondary replica.  

### Hyperscale

The Hyperscale service tier is only available in Azure SQL Database. This service tier has a unique architecture because it uses a tiered layer of caches and page servers to expand the ability to quickly access database pages without having to access the data file directly.

:::image type="content" source="../graphics/4-hyperscale-architecture-2.png" alt-text="Hyperscale architecture":::

Since the architecture leverages paired page servers, you have the ability to scale horizontally to put all of the data in caching layers. This new architecture also allows Hyperscale to support up to 100 TB of database size. Because of the use of snapshots, nearly instantaneous database backups can occur regardless of size and databases restores takes minutes rather than hours or days. You can also scale up or down in constant time to accommodate your workloads.

One other interesting piece in this architecture is how the log service was pulled out. The log service is used to feed the replicas as well as the page servers. Transactions can commit when the log service hardens to the landing zone, which means the consumption of the changes by a secondary compute replica is not required for a commit. Unlike other service tiers, the existence of secondary replicas is up to you to determine. You can configure zero to four secondary replicas, which can all be used for read-scale.

Similar to the other service tiers, an automatic failover will happen if service fabric determines it needs to, but the recovery time will depend on the existence of secondary replicas. For example, if you have zero replicas and a failover occurs, it will be similar to the General purpose service tier where it first needs to find spare capacity. If you have one or more replicas, recovery is faster and more closely aligns to the Business critical service tier.

Business critical maintains the highest performance and availability for workloads with small log writes that need low latency. But the Hyperscale service tier allows you to get a higher log throughput in terms of MB/second, provides for the largest database sizes, and provides up to four secondary replicas for higher levels of read scale. So you'll need to consider your workload when you choose between the two.

<p><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/point1.png"><a name="2"><b>Activity 2</a>: Basic HA in Azure SQL Database</b></p>

In this activity, you'll get to see how the General purpose tier of Azure SQL Database behaves similarly to a Failover Cluster Instance on-prem. The main difference is that on-prem, this can be time-consuming or tricky to set up, but with Azure SQL, you get it out of the box.


<p><img style="margin: 0px 15px 15px 0px;" src="../graphics/checkmark.png"><b>Steps</b></p>

**Step 1 - Connect to the Azure PowerShell module**  

Open PowerShell on your virtual machine (should be pinned to taskbar from Prerequisites) and run `Connect-AzAccount`. This will walk you through authenticating. This step basically sets you up to be able to use the Azure PowerShell module from Azure Data Studio.  

When this successful, you should see results like this (your account details with vary) in PowerShell. You can close PowerShell now.  

<pre>
Account                                            SubscriptionName                    TenantId
-------                                            ----------------                    --------
odl_user_165187@...com            Microsoft Managed Labs Spektra - 04           f94768c8-8714...</pre>

**Step 2 - Main activity**  

For the main part of this activity, you'll use the notebook called **basic-ha.ipynb** which is under `azuresqlworkshop\05-Availability\basic-ha\basic-ha.ipynb`. Navigate to that file in ADS to complete this activity, and then return here.     

<p style="border-bottom: 1px solid lightgrey;"></p>

<h2><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/pencil2.png"><a name="5.3">5.3 Business critical</h2></a>

You've seen some of the capabilities that Azure SQL offers generally as far as high availability goes in Azure SQL. In this topic, you'll move to the Business critical service tier, which is meant to obtain the highest availability of all Azure SQL service tiers (General purpose, Hyperscale, Business critical). Business critical is meant for mission-critical applications that need low latency and minimal downtime.  

More information about Business critical can be found [here](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-service-tier-business-critical).  


<p><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/point1.png"><a name="3"><b>Activity 3</a>: Turn-key AGs in Business critical</b></p>

In this activity, you'll upgrade your database to the Business critical tier and explore the offering, including read-replicas, availability zones, and increased performance.  


<p><img style="margin: 0px 15px 15px 0px;" src="../graphics/checkmark.png"><b>Steps</b></p>

**Step 1 - Upgrade your database to Business critical**  

It's easy to use the Azure portal GUI to modify your service tier. In this step, you'll revisit the Azure Cloud Shell and use the Azure CLI. Then, you'll confirm your changes using the Azure portal GUI.  

Navigate to the Azure portal and select the Azure Cloud Shell button in the top menu bar to open.  

![](../graphics/azcloudshell.png)  

Since we're using the Azure CLI, you can use Bash or PowerShell here, but the screenshots will be for Bash.  

![](../graphics/acsbash.png)  

Next, run `az account show` to confirm the default subscription matches the one you are using for the workshop.  

> Note: If it doesn't, you can run `az account list` to find the name of the subscription you are using for the workshop. Then, run `az account set --subscription 'my-subscription-name'` to set the default subscription for this Azure Cloud Shell session. You can confirm this worked by running `az account show` again.  
  

> Tip: You can't always use `CTRL + V` to paste in the Azure Cloud Shell (on Windows), but you can use `SHIFT + ENTER`.  

Now that you're set up, you can update the database's service tier.   

Run the following commands (adding your information) to update your service tier to Business critical and some other settings.  

First, set the `id` variable, replacing `0406` with your ID you've been using for the workshop.
```cli
id='0406'
```

Now, you can use the following command to update the service tier to `BusinessCritical`.  
```cli
az sql db update --resource-group azuresqlworkshop$id --server aw-server$id --name AdventureWorks$id --edition BusinessCritical --read-scale Enabled --zone-redundant false
```
This will take a few moments to complete, but while it's running, you can review some of the parameters we used:  
* `edition`: this term is a bit misleading, because it is really referring to the service tier, which is not the same as what edition means in the SQL Server box product.  
* `read-scale`: This is not enabled by default, but there is no additional cost associated with it. By enabling it, you're enabling one of your secondary replicas to be used as a readable secondary.  
* `zone-redundant`: By default, this is set to false, but you can set it to true if you want a multi-az deployment, with no additional cost. Note that this is only available in [certain regions](https://docs.microsoft.com/en-us/azure/availability-zones/az-overview#services-support-by-region) and not (yet) in Azure SQL managed instance.  

After it completes, you should see detailed information about the updates in the Azure Cloud Shell output under two main categories (though you'll also see indicators under several other properties):  
* `currentServiceObjectiveName`: should be `BC_Gen5_8` where `BC` stands for Business critical  
* `currentSku`:  
    * `name`: should be `BC_Gen5`
    * `tier`: should be `BusinessCritical`  


Another way to confirm this is to navigate to your database in the Azure portal and review the **Overview** tab, locating the **Pricing tier**.  

![](../graphics/overviewtab.png)  

> Note: There are many other ways to check this, but another way is through SSMS. If you right-click on your database and select **Properties** > **Configure SLO**, you can also view the changes.  

**Step 2 - Compare failover time to General purpose**  

In Activity 1, you forced a failover in your General purpose database using the notebook **basic-ha.ipynb**. If you recall, it took about one minute for the General purpose database. Now that you've switched to Business critical, will the failover be faster?  

For this step, you'll use the same notebook from Activity 1, which is under `azuresqlworkshop\05-Availability\basic-ha\basic-ha.ipynb`. Navigate to that file in ADS to complete this step, and then return here.  


**(Bonus) Step 3 - Leverage the read-only replica for reports**  

Since you enabled the `read-scale` parameter, you have the ability to use one of the secondary replicas for read-only workloads. In order to access the read-only replica in applications, you just have to add the following parameter to your connection string for a database:  
```
ApplicationIntent=ReadOnly;
```
In SSMS, create a new query connection (select **File** > **New** > **Database Engine Query**).  

![](../graphics/newdbenginequery.png)  

Using the same way you've been connecting to your Azure SQL Database logical server (either with SQL Auth or Azure AD Auth), select **Options**.  

![](../graphics/ssmsoptions.png)  

Select **Connection Properties**, and select **Reset All**. Then, under "Connect to database" select **Browser server** and select your AdventureWorks database.  

Then select **Additional Connection Parameters** and copy and paste the following into the text box. Finally, select **Connect**.  

```sql
ApplicationIntent=ReadOnly;
```  
>Note: In using SSMS, you have to specify the server and database to which you want to connect read-only, because there may be multiple databases in a server with different capabilities as far as readable secondaries goes.

To test, try the following query on your new database engine query, and observe the results. Is it what you would expect?  

```sql
SELECT DATABASEPROPERTYEX(DB_NAME(), 'Updateability')
```
![](../graphics/readonly.png)  

You can optionally re-connect and update the Additional Connection Parameters (replace `ReadOnly` with `ReadWrite`), and confirm you are accessing the read-write primary replica. `ReadWrite` is the default, so if you don't select anything, that's what you'll be in.    

![](../graphics/readwrite.png)  

<p style="border-bottom: 1px solid lightgrey;"></p>

<h2><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/pencil2.png"><a name="5.4">5.4 Higher availability</h2></a>

Azure SQL Database and Azure SQL Managed Instance provide great availability options by default among the various service tiers. There are some additional things you can do to increase or modify the availability of your databases/instances, and you can directly see the impact on the service level agreement (SLA). In this unit, you'll see how you can go further with various options for availability in Azure SQL.

### Availability zones

In the Business critical tier in Azure SQL Database, you can opt-in (for no additional fee) for a zone redundant configuration if your region supports that. At a high level, the Always On Availability Group (AG) that is running behind Business critical databases and managed instances is deployed across three different availability zones (AZ) within a region. An AZ is basically a separate datacenter within a given region with some distance between another AZ. This protects against catastrophic failures that may occur in a region to a datacenter.


:::image type="content" source="../graphics/7-availability-zones.png" alt-text="Availability zone architecture" border="false":::

From performance standpoint, there may be a small increase in network latency, since your AG is now spread across datacenters with some distance between them. For this reason, leveraging AZs is not turned on by default. You have the choice to opt for what's commonly called a "multi-az" or "single-az" deployment. Making this decision is as simple as adding a parameter to a PowerShell/Azure CLI command or checking a box in the portal.  

Availability Zones are relatively new to Azure SQL, so they're currently  available only in certain regions and service tiers. Over time, this capability is likely to be supported in more regions and potentially more service tiers. For example, recently the General Purpose tier for Azure SQL Database released a preview for the multi-az deployment.

### Azure SQL SLA

Azure SQL maintains a Service Level Agreement (SLA) which provides financial backing to the commitment to achieve and maintain Service Levels for the service. If your Service Level is not achieved and maintained as described in the SLA, you may be eligible for a credit towards a portion of your monthly service fees.

At the time of the most recent review of this unit, the highest availability (99.995%) can be achieved from an Azure SQL Database Business critical deployment with Availability Zones configured. Additionally, the Business critical tier is the only option in the industry which supplies RPO and RTO SLAs of 5 seconds and 30 seconds, respectively. RPO stands for recovery point object, which represents how much data one is potentially prepared and willing to lose in the worst case scenario. RTO stands for recovery time objective, which represents how much time it takes, if or when a disaster occurs, to be back up and running again.

For General Purpose or single-zone Business Critical deployments of Azure SQL Database or Azure SQL Managed Instance, the SLA is 99.99%.

The Hyperscale tier's SLA depends on the number of replicas. Recall, in Hyperscale you choose how many replicas you have, and if there are zero, when you fail over, it is more similar to that of General purpose. If you have replicas, then a failover is more similar to that of Business critical. The corresponding SLA depending on number of replicas is:  

* 0 replicas: 99.5%
* 1 replica: 99.9%
* 2 or more replicas: 99.99%

### Geo-replication and auto-failover groups

Outside of making a selection of service tier (and availability zones where applicable), there are some other options for getting read scale or the ability to fail over to another region: geo-replication and auto-failover groups. In SQL Server on-premises, configuring either of these options is something that would take much planning, coordination, and time.

The cloud, and Azure SQL specifically, have made this a much easier implementation for you. For both geo-replication and auto-failover groups, this amounts to a few clicks in the Azure portal or a few commands in PowerShell/Azure CLI.

There are some decision points that can help you decide if geo-replication or auto-failover groups are best for your scenario.

|                                              | Geo-replication | Failover groups  |
|:---------------------------------------------| :-------------- | :----------------|
| Automatic failover                           |     No          |      Yes         |
| Fail over multiple databases simultaneously  |     No          |      Yes         |
| User must update connection string after failover      |     Yes         |      No          |
| SQL Managed Instance support                   |     No          |      Yes         |
| Can be in same region as primary             |     Yes         |      No          |
| Multiple replicas                            |     Yes         |      No          |
| Supports read-scale                          |     Yes         |      Yes         |
| &nbsp; | &nbsp; | &nbsp; |


<p><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/point1.png"><a name="4"><b>Activity 4</a>: Geo-distributed auto-failover groups with read-scale in Business critical</b></p>

In this activity, you'll configure auto-failover groups for your Azure SQL Database. You'll then initiate a failover and observe the results, leveraging an application.  

<p><img style="margin: 0px 15px 15px 0px;" src="../graphics/checkmark.png"><b>Steps</b></p>

For this activity, you'll use the notebook called **fg-powershell.ipynb** which is under `azuresqlworkshop\05-Availability\fg\fg-powershell.ipynb`. Navigate to that file in ADS to complete this activity, and then return here.     

>Note: This activity is based off of a [tutorial in the documentation](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-implement-geo-distributed-database?tabs=azure-powershell) that also has information about using the Azure portal and the Azure CLI. In this exercise, you will use the Az PowerShell module.  

In this module and throughout the activities, you got to get hands-on with many availability-related features that are available for Azure SQL. In the next module, you'll take a look at one of two scenarios that challenge you to create a solution leveraging Azure SQL.  

<p style="border-bottom: 1px solid lightgrey;"></p>

<h2><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/pencil2.png"><a name="5.5">5.5 Availability and consistency</h2></a>

You now know about the high availability and disaster recovery architectures in Azure SQL Managed Instance and Azure SQL Database. Potentially coming from a SQL Server background, you're aware of how database availability and consistency can be managed, so in this unit you'll learn about how it compares to Azure SQL.

### Database availability

In both Azure SQL Database and Azure SQL Managed Instance, you cannot set a database state to `OFFLINE` and `EMERGENCY`. If you think about it, `OFFLINE` doesn't make sense, since you cannot attach databases, and `EMERGENCY` being restricted means you cannot do emergency mode repair, but you shouldn't have to, since Azure manages and maintains the service. However, other capabilities such as `RESTRICTED_USER` and Dedicated Admin Connection (DAC) are allowed in Azure SQL Database.  

Accelerated Database Recovery (ADR) is a capability built in to the engine. With ADR, the transaction log is aggressively truncated and a Persisted Version Store (PVS) is used. This technology allows you to perform a transaction rollback instantly, solving a well-known issue with long running transactions. It also means Azure SQL can recover databases quickly.  

In Azure SQL Database and Azure SQL Managed Instance, ADR greatly increases the general database availability, and is a big factor in the SLA. For these reasons, ADR is on by default and it cannot be turned off.

### Database consistency

As you learned in the beginning of the module, multiple copies of your data and backups exist both locally and across regions. On a regular basis, backup and restore integrity checks are performed. Detection for 'lost write' and 'stale read' is also in place. As a user, you can execute `DBCC CHECKDB` (no repair) and `CHECKSUM` is on by default. In the backend, Auto Page Repair will occur when possible, and there is data integrity error alert monitoring. If there is no impact, repair without notification will occur, but if there is any impact proactive notification will be provided.  

<p style="border-bottom: 1px solid lightgrey;"></p>

<h2><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/pencil2.png"><a name="5.6">5.6 Configuring and monitoring</h2></a>
 
Now that you know about all the possibilities, you'll need to create a strategy for the specific workload which your Azure SQL Database or Azure SQL Managed Instance is a part of.

### Making the right choices

A big part of this process is stepping back and thinking about the requirements of your workload. Some questions to consider include:

- Do you need long term backups? Or is 1-35 days long enough?
- What are your RTO and RPO needs?
- After reviewing the SLA, what service tier makes the most sense?
- Do you need Availability Zones?
- Do you need geo-replicated HADR or failover groups?
- Is your application ready?

The answers to these questions will help you in narrowing down what configuration you should deploy to meet your availability requirements.

The last question, *Is your application ready?*, if often overlooked by the data professional. However, this consideration is crucial to actually achieving the SLA you desire. You need to make sure that not only your database is meeting your availability requirements, but also that your application is meeting those requirements. Additionally, you'll want to make sure that the connectivity between the data and the application(s) meets your requirements. As an example, if your application and database are in different regions, this will increase the network latency. You should, as a best practice, place your application and data as close together as possible. Throughout the module, you've also seen how important implementing retry logic in your applications is to mainintaing availability.

### Monitoring availability

Azure SQL provides several tools and capabilities to monitor certain aspects of availability. This includes using the Azure portal, T-SQL, and interfaces such as Powershell, az CLI, and REST APIs.

Some of the examples of using these tools to monitor availability include:

#### Region and data center availability

The availability of regions and data centers is critical for the availability of a Managed Instance or Database deployment. **Azure status** and **Azure Service Health** are key to understanding any outages for a data center or region including specific services such as Azure SQL.  

Azure status is a dashboard showing any service impacting issues across Azure global regions. An RSS feed is available to get notification of any change to Azure status.  

You can view Azure Service Health through the Azure portal which include service issues, planned maintenance events, health advisories, and health history. You also have the ability to setup alerts to notify you through email or SMS for any event that might affect availability.  

#### Instance, server, and database availability

Aside from Azure service impacting events, you can view the availability of your Azure SQL Managed Instance or Azure Database Server and databases through the Azure portal.  

One of the primary methods to view a possible reason for a Managed Instance or Database to not be available is by examining **Resource Health** through the Azure Portal or REST APIs.  

You can always use standard SQL Server tools such as SQL Server Management Studio to connect to a Managed Instance or Database server and check the status of these resources through the tool or T-SQL queries.  

In addition, interfaces such as **az CLI** can show the status of Azure SQL such as:  

**az sql mi list** - List the status of managed instances  
**az sql db list** - List the status of Azure SQL Databases  

Powershell cmdlets can also be used to find out the availability of an Azure SQL Database such as:  

**Get-AzSQLDatabase** - Get all the databases on a server and their details including status.  

**REST APIs**, although not as simple to use, can also be used to get the status of Managed Instances and Databases.

#### Backup and Restore History

Azure SQL automatically backs up databases and transaction logs. Although standard backup history is not available, **Long-term backup retention history** can be viewed through the Azure portal or CLI interfaces.  

Any restore of a database using Point in time restore results in the creation of a new database so the history of restore can be viewed as looking at the creation of a new database. All operations to create a new database can be viewed through Azure Activity Logs.

#### Replica status

Replicas are used for Business Critical service tiers. You can view the status of a replica through the DMV **sys.dm_database_replica_states**.

#### Failover reasons

To check the reasons for a failover event for Azure SQL Managed Instance or database deployment, check the Resource Health through the Azure portal or REST APIs.

#### System Center Management Pack for Azure SQL

System Center provides management packs to monitor Azure SQL Managed Instance and Azure SQL Database. Consult the management pack documentation for requirements and usage.  

In this module and throughout the activities, you got to get hands-on with many availability-related features that are available for Azure SQL. In the next module in the Azure SQL fundamentals learning path, you'll take a look at one of two scenarios that challenge you to create a solution leveraging Azure SQL.  

<p style="border-bottom: 1px solid lightgrey;"></p>


<p><img style="margin: 0px 15px 15px 0px;" src="../graphics/owl.png"><b>For Further Study</b></p>
<ul>
    <li><a href="https://docs.microsoft.com/en-us/azure/sql-database/sql-database-business-continuity" target="_blank">Business continuity overview</a></li>
    <li><a href="https://docs.microsoft.com/en-us/azure/sql-database/sql-database-high-availability" target="_blank">High Availability overview</a></li>
    <li><a href="https://docs.microsoft.com/en-us/azure/sql-database/sql-database-disaster-recovery" target="_blank">Outage Recovery Guidance</a></li>
    <li><a href="https://docs.microsoft.com/en-us/azure/sql-database/sql-database-disaster-recovery-drills" target="_blank">Recovery drills</a></li>    
    <li><a href="https://docs.microsoft.com/en-us/azure/sql-database/sql-database-vcore-resource-limits-single-databases" target="_blank">vCore Resource Limits</a></li>    
    <li><a href="https://docs.microsoft.com/en-us/azure/sql-database/sql-database-implement-geo-distributed-database?tabs=azure-powershell" target="_blank">Docs: Implement a geo-distributed database</a></li>    
</ul>

<p><img style="float: left; margin: 0px 15px 15px 0px;" src="../graphics/geopin.png"><b >Next Steps</b></p>

Next, Continue to <a href="https://github.com/microsoft/sqlworkshops-azuresqlworkshop/blob/master/azuresqlworkshop/06-PuttingItTogether.md" target="_blank"><i> 06 - Putting it all together</i></a>.