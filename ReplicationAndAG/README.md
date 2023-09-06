1. [Introduction](#introduction)
1. [Prerequisites](#prerequisites)
1. [How to use](#how-to-use)
1. [Scenarios](#scenarios)
1. [Output folders](#output-folders)
1. [Logging](#logging)
1. [Permissions](#permissions)
1. [Targeted SQL instances](#targeted-sql-instances)
1. [Security](#security)
1. [Sample output](#sample-output)
1. [Test Suite](#test-suite)
1. [Script to cleanup an incomplete shutdown of SQL LogScout](#script-to-cleanup-an-incomplete-shutdown-of-sql-logscout)
1. [SQL LogScout as a scheduled task in Windows Task Scheduler](#schedule-sql-logscout-as-a-task-to-automate-execution)

# Introduction
ReplicationANDAG script allows us to seamlessly configure replication in AG.It helps us to configure publisher, distributor and subscribers in AG. 
The script supports multiple configuration like there could be variable number of nodes participating in AG. The script supports sql server instances which are participating in AG could be either in single subnet or multisubnet environment.
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

