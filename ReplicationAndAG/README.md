1. [Introduction](#introduction)
1. [Prerequisites](#prerequisites)
1. [How to use](#how-to-use)
1. [Cleanup an incomplete or complete setup of replication in AG](#cleanup-an-incomplete-or-complete-setup-of-replication-in-ag)

# Introduction
ReplicationAndAG script allows us to seamlessly configure replication in AG.It helps us to configure publisher, distributor and subscriber in AG. 
The script supports multiple configuration like there could be variable number of nodes participating in AG, sql server instances which are participating in AG could be either in single subnet or multisubnet environment.
The script first configures the AG environemnt and then configure the distributor, publisher and subscriber.

# Prerequisites
- All the sql server instances participating in an AG should have the same version of sql server.
- The host computer must be a WFSC node. The instances of SQL Server that host availability replicas for a 
  given availability group should reside on separate nodes of the cluster.
- Enable AG feature in sql config manager for the all the sql server instances participating in AG.
- Start the sql server agent if not started.
- SQL sever instances should be running under a domain service account.
- If the sql server instances that are hosting the availability replicas of an AG run as different account,then
  the login of each account must be created in master on the other server instance and that login must be granted CONNECT permission.
- Make 2 shared folders one for backups and other for replication and provide the path in backupSharePath and replDirPath folder.
- Give sql service account control of the following registry location for all the nodes.
  HKLM\SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo
  HKLM\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo
- In case of AG in multisubnet environment MultiSubnetFailover property should be added and set to true in the log reader
  and distribution agent parameter.
- Publication and subscription databases should be created beforehand.
- While running the cleanup script update the primary replica values with the current primary replica.
  This is important in the scenario in case a failover has happened and the primary replica changes.
- Currently AG is being created with some default parameters. In case some parameters needs to be modified,
  the script needs to be modified accordingly.

# How to use
Open all the 3 scripts i.e distag.sql, pubag.sql and subag.sql and set all the input variables in it.

![image](https://github.com/sbhuwalka/ReplScripts/assets/91614203/51cd9184-879d-42a7-851e-baafb83381d9)

The above image shows the section in script to input all the variables.
There is a variable called **generateScript** in the script. This determines whether we need to generate the script to setup the replication in AG or to cleanup the existing setp or both.

![image](https://github.com/sbhuwalka/ReplScripts/assets/91614203/df7771f2-d188-4c33-912e-615227eeb98b)

As shown in the above image if we want to generate the script to setup the replication in AG we can use the value of variable as setup.

- Now first run the distag.sql and then copy the output. The output would be in tsql format. Execute the output to setup distributors in AG
- After that run the pubag.sql and then copy the output. Output here would also be in tsql format. Execute the output to setup publishers in AG. After that we can create publication using SSMS UI or using the 
stored procs.
- After that run the subag.sql and then copy the output. Output here would also be in tsql format. Execute the output to setup subscribers in AG. Subscription would also be created by this script.
 
# Cleanup an incomplete or complete setup of replication in AG
In case we encounter any errors while running the script then the incomplete setup of replication in AG or in case if we want to cleanup the existing setup then the cleanup script can be used.
- First of all provide all the inputs in all the 3 scripts. Be cautious while mentioning the primary replica as they might have changed, as compared to what it was during setup, because of failover.
- In the **generateScript** variable provide the value as cleanup to generate the cleanup script.
- After that run the respective script for cleaning up the respective entity i.e. for example to cleanup the subscribers in AG run subag.sql with generateScript variable set to cleanup. After that copy the output 
  of this and execute the output to cleanup the subscriber in AG.

