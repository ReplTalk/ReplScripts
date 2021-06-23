/*
Date: 12/2/2020
Author: James Ferebee (james.ferebee@microsoft.com)
Modified: Taiyeb Zakir added validation
 
DISCLAIMER:
This script is not intended for production use or guaranteed to work. This is provided for reference on a working configuration. There are various settings that may need to be changed from install to install like whether the cluster is multi-subnet etc. 
 
The design of the environment for this was:
1) 4 SQL nodes (2 nodes host publisher instance as well as distributor instance, 2 separate nodes as subscriber)
2) All nodes are in the same subnet
3) SQL and agent services are under the same account and have sysadmin
4) All nodes can access the same network share and sqlsvc account has full control of that directory.
 
This script isn't pretty and doesn't have error handling (yet). As such if you have issues, it is recommended to run it sectino at a time.
Over time the script will be more robust and involve error handling etc
 
*/
 
 
/*
******************************************************
BEFORE RUNNING:
******************************************************
--Install SQL
--Cluster windows
--Enable AG feature in sql config manager
--start agent and set to automatic
--validate network protocols are correctly configured
--make Backups folder -  BackupShare var
--make Repl folder - ReplDir var
--give sql server service account control of the registry locations using the link as ref: 
---HKLM\SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo
---HKLM\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo
*/
 
 
 
/*
***************************************************************
***********************>Variables - Set Properly Below<********
***************************************************************
*/
 
 
--Run query in SQLCMD mode.
 
--Distributor & Repl Config Settings
:SETVAR DisNode1 "TR-VMAGDis1"
:SETVAR DisNode2 "TR-VMAGDis2"
:SETVAR Dis1InsName "MSSQLSERVER"  
:SETVAR Dis2InsName "MSSQLSERVER"  
:SETVAR DisNode1Bios "TR-VMAGDis1"
:SETVAr DisNode2Bios "TR-VMAGDis2"
:SETVAR SqlAcct "[CSSSQL\sqlsvc]"
:SETVAR SqlAgtAcct "[CSSSQL\sqlsvc]"
:SETVAR BackupShare "\\csssql-vmdc\Share\backup\"
:SETVAR ReplDir "\\csssql-vmdc\Share\Repl\"
:SETVAR FQDNExtension ".CSSSQL.lab"
:SETVAR DisListenerName "DisAGListener"
:SETVAR DisListenerIP1 "192.168.1.25"
:SETVAR SubnetMask "255.255.255.0"
:SETVAR DisListenerPort "1433"
:SETVAR DistDatabase "distributiondb"
:SETVAR DisAGName "DisAg"
:SETVAR DisAgEndpoint "5022"
:SETVAR DisAdminPassword "Password1"
 
--Publication Nodes Settings
:SETVAR NodePub1 "TR-VMAGPub1"
:SETVAR NodePub2 "TR-VMAGPub2"
:SETVAR Pub1InsName "MSSQLSERVER" 
:SETVAR Pub2InsName "MSSQLSERVER" 
:SETVAR NodePub1Bios "TR-VMAGPub1"
:SETVAR NodePub2Bios "TR-VMAGPub2"
:SETVAR PubListenerName "PubAGListener"
:SETVAR PubListenerIP1 "192.168.1.31"
:SETVAR PubListenerPort "1433"
:SETVAR PubName "TranRepl-TestPubAGDB"
:SETVAR AGPubDatabase "TESTPUBAGDB"
:SETVAR AGPubName "PubAg"
:SETVAR PubAgEndpoint "5022"
 
--Subscriber Nodes Settings
:SETVAR NodeSub1 "TR-VMAGSub1"
:SETVAR NodeSub2 "TR-VMAGSub2"
:SETVAR Sub1InsName "MSSQLSERVER"
:SETVAR Sub2InsName "MSSQLSERVER"
:SETVAR NodeSub1Bios "TR-VMAGSub1"
:SETVAR NodeSub2Bios "TR-VMAGSub2"
:SETVAR SubListenerName "SubAGListener"
:SETVAR SubListenerIP1 "192.168.1.42"
:SETVAR SubListenerPort "1433"
:SETVAR AgSubName "SubAg"
:SETVAR SubAgEndpoint "5022"
:SETVAR SubDB "TESTPUBAGDB_Sub"
 
 
/*
***************************************************************
***********************>DIS Steps<******************************
***************************************************************
*/
 
 
:CONNECT $(DisNode1)
Sp_adddistributor @distributor=@@servername, @password= '$(DisAdminPassword)';
GO
:CONNECT $(DisNode2)
Sp_adddistributor @distributor=@@servername, @password= '$(DisAdminPassword)';
GO
:CONNECT $(DisNode1)
Sp_adddistributiondb @database='$(DistDatabase)', @security_mode = 1;
GO
ALTER DATABASE $(DistDatabase) SET RECOVERY FULL;
GO


--:CONNECT $(DisNode1)
--USE [master];
--CREATE LOGIN $(SqlAcct) FROM WINDOWS WITH DEFAULT_DATABASE=[master];
--GO
--ALTER SERVER ROLE sysadmin ADD MEMBER $(SqlAcct);
--GO
--USE [master];
--CREATE LOGIN $(SqlAgtAcct) FROM WINDOWS WITH DEFAULT_DATABASE=[master];
--GO
--ALTER SERVER ROLE sysadmin ADD MEMBER $(SqlAgtAcct);
--GO
--CREATE ENDPOINT [Hadr_endpoint]
--AS TCP (LISTENER_PORT = $(DisAgEndpoint))
--FOR DATA_MIRRORING (ROLE = ALL);
--GO
--IF (SELECT state FROM sys.endpoints WHERE name = N'Hadr_endpoint') <> 0
--BEGIN
--ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED
--END;
--GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO $(SqlAcct);
--GO
--IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AlwaysOn_health')
--BEGIN
--ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON);
--END
--IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health')
--BEGIN
--ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START;
--END;
 
--:CONNECT $(DisNode2)
--USE [master];
--CREATE LOGIN $(SqlAcct) FROM WINDOWS WITH DEFAULT_DATABASE=[master];
--GO
--ALTER SERVER ROLE sysadmin ADD MEMBER $(SqlAcct);
--GO
--USE [master];
--CREATE LOGIN $(SqlAgtAcct) FROM WINDOWS WITH DEFAULT_DATABASE=[master];
--GO
--ALTER SERVER ROLE sysadmin ADD MEMBER $(SqlAgtAcct);
--GO
--CREATE ENDPOINT [Hadr_endpoint]
--AS TCP (LISTENER_PORT = $(DisAgEndpoint))
--FOR DATA_MIRRORING (ROLE = ALL);
--GO
--IF (SELECT state FROM sys.endpoints WHERE name = N'Hadr_endpoint') <> 0
--BEGIN
--ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED
--END;
--GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO $(SqlAcct);
--GO
--IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AlwaysOn_health')
--BEGIN
--ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON);
--END
--IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health')
--BEGIN
--ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START;
--END;
 
:CONNECT $(DisNode1)
USE [master]; 
CREATE AVAILABILITY GROUP $(DisAGName)
FOR REPLICA ON N'$(DisNode1)' WITH 
(
ENDPOINT_URL = N'TCP://$(DisNode1Bios)$(FQDNExtension):$(DisAgEndpoint)', 
FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, 
SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL)
)
,
N'$(DisNode2)' WITH (ENDPOINT_URL = N'TCP://$(DisNode2Bios)$(FQDNExtension):$(DisAgEndpoint)', FAILOVER_MODE = MANUAL, 
AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, 
SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));
 
ALTER AVAILABILITY GROUP $(DisAGName)
ADD LISTENER N'$(DisListenerName)' (
WITH IP
((N'$(DisListenerIP1)', N'$(SubnetMask)')
)
, PORT=$(DisListenerPort));
GO
 
:Connect $(DisNode2)
ALTER AVAILABILITY GROUP $(DisAGName) JOIN;
GO
 
:Connect $(DisNode1)
BACKUP DATABASE $(DistDatabase) TO  DISK = N'$(BackupShare)$(DistDatabase).bak' 
WITH NOFORMAT, INIT,  NAME = N'$(DistDatabase)-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10;
GO
 
BACKUP LOG $(DistDatabase) TO  DISK = N'$(BackupShare)$(DistDatabase)_log.trn' 
WITH NOFORMAT, INIT,  NAME = N'$(DistDatabase)-Log Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10;
GO
ALTER AVAILABILITY GROUP $(DisAGName) ADD DATABASE $(DistDatabase);  
GO
 
:Connect $(DisNode2)
RESTORE DATABASE $(DistDatabase) FROM DISK = N'$(BackupShare)$(DistDatabase).bak'  WITH NORECOVERY, stats=10;
GO
RESTORE LOG $(DistDatabase) FROM DISK = N'$(BackupShare)$(DistDatabase)_log.trn'  WITH NORECOVERY, stats=10;
GO
 
ALTER DATABASE $(DistDatabase) SET HADR AVAILABILITY GROUP = $(DisAGName);
GO
 
sp_adddistributiondb '$(DistDatabase)';
GO
 
 
 
/*
***************************************************************
***********************>Publisher Steps<***********************
***************************************************************
*/
 
 
 
 
:CONNECT $(NodePub1)
USE [master];
CREATE LOGIN $(SqlAcct) FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO
ALTER SERVER ROLE sysadmin ADD MEMBER $(SqlAcct) 
GO
USE [master];
CREATE LOGIN $(SqlAgtAcct) FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO
ALTER SERVER ROLE sysadmin ADD MEMBER $(SqlAgtAcct);
GO
 
CREATE ENDPOINT [Hadr_endpoint]
AS TCP (LISTENER_PORT = $(PubAgEndpoint))
FOR DATA_MIRRORING (ROLE = ALL);
GO
IF (SELECT state FROM sys.endpoints WHERE name = N'Hadr_endpoint') <> 0
BEGIN
ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED
END;
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO $(SqlAcct);
 
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AlwaysOn_health')
BEGIN
ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON);
END
IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health')
BEGIN
ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START;
END;
GO
CREATE DATABASE $(AGPubDatabase);
GO
ALTER DATABASE $(AGPubDatabase) SET RECOVERY FULL;
GO
USE $(AgPubDatabase);
GO
CREATE TABLE TESTTBL (cola int NOT NULL, CONSTRAINT PK_cola PRIMARY KEY CLUSTERED (cola));
GO
INSERT INTO TESTTBL values (1);
GO
 
 
:CONNECT $(NodePub2)
USE [master];
CREATE LOGIN $(SqlAcct) FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO
ALTER SERVER ROLE sysadmin ADD MEMBER $(SqlAcct);
GO
USE [master];
CREATE LOGIN $(SqlAgtAcct) FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO
ALTER SERVER ROLE sysadmin ADD MEMBER $(SqlAgtAcct);
GO
CREATE ENDPOINT [Hadr_endpoint]
AS TCP (LISTENER_PORT = $(PubAgEndpoint))
FOR DATA_MIRRORING (ROLE = ALL);
GO
IF (SELECT state FROM sys.endpoints WHERE name = N'Hadr_endpoint') <> 0
BEGIN
ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED
END;
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO $(SqlAcct);
 
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AlwaysOn_health')
BEGIN
ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON);
END
IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health')
BEGIN
ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START;
END;
GO
 
:CONNECT $(NodePub1)
USE [master]; 
CREATE AVAILABILITY GROUP $(AGPubName)
FOR REPLICA ON N'$(NodePub1)' WITH 
(
ENDPOINT_URL = N'TCP://$(NodePub1Bios)$(FQDNExtension):$(PubAgEndpoint)', 
FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, 
SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL)
)
,
N'$(NodePub2)' WITH (ENDPOINT_URL = N'TCP://$(NodePub2Bios)$(FQDNExtension):$(PubAgEndpoint)', FAILOVER_MODE = MANUAL, 
AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, 
SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));
GO
 
ALTER AVAILABILITY GROUP $(AGPubName)
ADD LISTENER N'$(PubListenerName)' 
(
WITH IP
((N'$(PubListenerIP1)', N'$(SubnetMask)'))
, PORT=$(PubListenerPort));
GO
 
:Connect $(NodePub2)
ALTER AVAILABILITY GROUP $(AGPubName) JOIN;
GO
 
:Connect $(NodePub1)
BACKUP DATABASE $(AGPubDatabase) TO  DISK = N'$(BackupShare)$(AGPubDatabase).bak' 
WITH NOFORMAT, INIT,  NAME = N'$(AGPubDatabase)-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10;
GO
 
BACKUP LOG $(AGPubDatabase) TO  DISK = N'$(BackupShare)$(AGPubDatabase)_log.trn' 
WITH NOFORMAT, INIT,  NAME = N'$(AGPubDatabase)-Log Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10;
GO
ALTER AVAILABILITY GROUP $(AGPubName) ADD DATABASE $(AGPubDatabase);  
GO
 
:Connect $(NodePub2)
RESTORE DATABASE $(AGPubDatabase) FROM DISK = N'$(BackupShare)$(AGPubDatabase).bak'  WITH NORECOVERY, stats=10;
GO
RESTORE LOG $(AGPubDatabase) FROM DISK = N'$(BackupShare)$(AGPubDatabase)_log.trn'  WITH NORECOVERY, stats=10;
GO
 
ALTER DATABASE $(AGPubDatabase) SET HADR AVAILABILITY GROUP = $(AGPubName);
GO
 
 
/*
 
***************************************************************
***********************>Add Publisher to Dis Steps<****************
***************************************************************
*/
 
 
/* Add Aliases to resolve listener port 
:Connect $(NodePub1)
--64 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='$(DisListenerName)', @type='REG_SZ',
  @value='DBMSSOCN,$(DisListenerName),$(DisListenerPort)';
GO
--32 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='$(DisListenerName)', @type='REG_SZ',
  @value='DBMSSOCN,$(DisListenerName),$(DisListenerPort)';
GO
 
:Connect $(NodePub2)
--64 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='$(DisListenerName)', @type='REG_SZ',
  @value='DBMSSOCN,$(DisListenerName),$(DisListenerPort)';
GO
--32 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='$(DisListenerName)', @type='REG_SZ',
  @value='DBMSSOCN,$(DisListenerName),$(DisListenerPort)';
GO
 
 
 
:Connect $(DisNode1)
--64 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='$(DisListenerName)', @type='REG_SZ',
  @value='DBMSSOCN,$(DislistenerName),$(DisListenerPort)';
GO
--32 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='$(DisListenerName)', @type='REG_SZ',
  @value='DBMSSOCN,$(DislistenerName),$(DisListenerPort)';
GO
--64 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='SubListener', @type='REG_SZ',
  @value='DBMSSOCN,$(SubListenerName),$(SubListenerPort)';
GO
--32 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='SubListener', @type='REG_SZ',
  @value='DBMSSOCN,$(SubListenerName),$(SubListenerPort)';
GO
--64 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='PubListener', @type='REG_SZ',
  @value='DBMSSOCN,$(PubListenerName),$(PubListenerPort)';
GO
--32 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='PubListener', @type='REG_SZ',
  @value='DBMSSOCN,$(PubListenerName),$(PubListenerPort)';
GO
 
 
 
 
:Connect $(DisNode2)
--64 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='$(DisListenerName)', @type='REG_SZ',
  @value='DBMSSOCN,$(DislistenerName),$(DisListenerPort)';
GO
--32 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='$(DisListenerName)', @type='REG_SZ',
  @value='DBMSSOCN,$(DislistenerName),$(DisListenerPort)';
GO
--64 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='SubListener', @type='REG_SZ',
  @value='DBMSSOCN,$(SubListenerName),$(SubListenerPort)';
GO
--32 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='SubListener', @type='REG_SZ',
  @value='DBMSSOCN,$(SubListenerName),$(SubListenerPort)';
GO
--64 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='PubListener', @type='REG_SZ',
  @value='DBMSSOCN,$(PubListenerName),$(PubListenerPort)';
GO
--32 bit alias
EXEC master.dbo.xp_regwrite @rootkey='HKEY_LOCAL_MACHINE',  
  @key='SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo', @value_name='PubListener', @type='REG_SZ',
  @value='DBMSSOCN,$(PubListenerName),$(PubListenerPort)';
GO
*/ 
 
 
:Connect $(DisNode1)
sp_adddistpublisher @Publisher= '$(NodePub1)', @distribution_db= '$(DistDatabase)', @working_directory='$(ReplDir)';
GO
sp_adddistpublisher @Publisher= '$(NodePub2)', @distribution_db= '$(DistDatabase)', @working_directory='$(ReplDir)';
GO
 
 
:Connect $(DisNode2)
sp_adddistpublisher @Publisher= '$(NodePub1)', @distribution_db= '$(DistDatabase)', @working_directory='$(ReplDir)';
GO
sp_adddistpublisher @Publisher= '$(NodePub2)', @distribution_db= '$(DistDatabase)', @working_directory='$(ReplDir)';
GO
 
 
 
 
 
:Connect $(NodePub1)
sp_adddistributor @distributor = '$(DisListenerName)', @password = '$(DisAdminPassword)';
GO
 
:Connect $(NodePub2)
sp_adddistributor @distributor = '$(DisListenerName)', @password = '$(DisAdminPassword)';
GO
 
 
 
/*
***************************************************************
***********************>Add Repl To Pub & Finish Sub<**********
***************************************************************
*/
 
 
 
 
 
 
:Connect $(NodePub1) 
EXEC sys.sp_replicationdboption
@dbname = '$(AGPubDatabase)',
@optname = 'publish',
@value = 'true'
 
-- Adding the transactional publication
use $(AGPubDatabase);
GO
exec sp_addpublication @publication = N'$(PubName)', @description = N'Transactional publication of database ''TESTPUBAGDB'' from Publisher ''TR-VMAGPUB1''.', @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'false', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'false', @allow_sync_tran = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'false', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false';
GO
 
exec sp_addpublication_snapshot @publication = N'$(PubName)', @frequency_type = 1, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 8, @frequency_subday_interval = 1, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1;
GO
 
exec sp_addarticle @publication = N'$(PubName)', @article = N'TESTTBL', @source_owner = N'dbo', @source_object = N'TESTTBL', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'TESTTBL', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboTESTTBL', @del_cmd = N'CALL sp_MSdel_dboTESTTBL', @upd_cmd = N'SCALL sp_MSupd_dboTESTTBL';
GO
 
 
 
 
:Connect $(DisNode1) 
USE $(DistDatabase);
GO 
EXEC sys.sp_redirect_publisher
@original_publisher = '$(NodePub1)',
@publisher_db = '$(AGPubDatabase)',
@redirected_publisher = '$(PubListenerName)';
GO
 
:CONNECT $(NodeSub1)
USE [master];
CREATE LOGIN $(SqlAcct) FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO
ALTER SERVER ROLE sysadmin ADD MEMBER $(SqlAcct);
GO
USE [master];
CREATE LOGIN $(SqlAgtAcct) FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO
ALTER SERVER ROLE sysadmin ADD MEMBER $(SqlAgtAcct);
GO
CREATE ENDPOINT [Hadr_endpoint]
AS TCP (LISTENER_PORT = $(SubAgEndpoint))
FOR DATA_MIRRORING (ROLE = ALL);
GO
IF (SELECT state FROM sys.endpoints WHERE name = N'Hadr_endpoint') <> 0
BEGIN
ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED
END;
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO $(SqlAcct);
 
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AlwaysOn_health')
BEGIN
ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON);
END
IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health')
BEGIN
ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START;
END;
GO
 
 
 
:CONNECT $(NodeSub2)
USE [master];
CREATE LOGIN $(SqlAcct) FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO
ALTER SERVER ROLE sysadmin ADD MEMBER $(SqlAcct);
GO
USE [master];
CREATE LOGIN $(SqlAgtAcct) FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO
ALTER SERVER ROLE sysadmin ADD MEMBER $(SqlAgtAcct);
GO
CREATE ENDPOINT [Hadr_endpoint]
AS TCP (LISTENER_PORT = $(SubAgEndpoint))
FOR DATA_MIRRORING (ROLE = ALL);
GO
IF (SELECT state FROM sys.endpoints WHERE name = N'Hadr_endpoint') <> 0
BEGIN
ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED
END;
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO $(SqlAcct);
 
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AlwaysOn_health')
BEGIN
ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON);
END
IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health')
BEGIN
ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START;
END;
GO
 
:CONNECT $(NodeSub1)
USE [master]; 
CREATE AVAILABILITY GROUP $(AgSubName)
FOR REPLICA ON N'$(NodeSub1)' WITH 
(
ENDPOINT_URL = N'TCP://$(NodeSub1Bios)$(FQDNExtension):$(SubAgEndpoint)', 
FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, 
SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL)
)
,
N'$(NodeSub2)' WITH (ENDPOINT_URL = N'TCP://$(NodeSub2Bios)$(FQDNExtension):$(SubAgEndpoint)', FAILOVER_MODE = MANUAL, 
AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, 
SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));
GO
 
 
ALTER AVAILABILITY GROUP $(AGSubName)
ADD LISTENER N'$(SubListenerName)' 
(
WITH IP
((N'$(SubListenerIP1)', N'$(SubnetMask)'))
, PORT=$(SubListenerPort));
GO
 
 
:Connect $(NodeSub2)
ALTER AVAILABILITY GROUP $(AgSubName) JOIN;
GO
 
:Connect $(NodePub1)
USE $(AGPubDatabase);
GO 
EXEC sp_addsubscription @publication = N'$(PubName)',
@subscriber = N'$(SubListenerName)',
@destination_db = N'$(SubDB)',
@subscription_type = N'Push',
@sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0;
GO 
EXEC sp_addpushsubscription_agent @publication = N'$(PubName)',
@subscriber_db = N'$(SubDB)', @job_login = null, @job_password = null, @subscriber_security_mode = 1, @frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20191125, @active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO
 
:Connect $(DisNode2) 
EXEC master.dbo.sp_addlinkedserver @server =N'$(SubListenerName)', @srvproduct=N'SQL Server';
GO 
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'$(SubListenerName)', 
@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL;
GO
 
:Connect $(NodePub2)  
EXEC master.dbo.sp_addlinkedserver @server =N'$(SubListenerName)', @srvproduct=N'SQL Server';
GO 
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'$(SubListenerName)', 
@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL;
GO
 
:Connect $(DisNode1)
Use $(DistDatabase);
GO
sp_redirect_publisher   
    @original_publisher = '$(NodePub1)',  
    @publisher_db = '$(AGPubDatabase)'   
    , @redirected_publisher = '$(PubListenerName)';
GO
 
 --not needed. 
--sp_redirect_publisher   
--    @original_publisher = '$(NodePub2)',  
--    @publisher_db = '$(AGPubDatabase)'   
--    , @redirected_publisher = '$(PubListenerName)';
GO
 
:Connect $(NodeSub1)
USE [master]
RESTORE DATABASE $(SubDB)
FROM  DISK =N'$(BackupShare)$(AGPubDatabase).bak' WITH  FILE = 1, 
MOVE N'TESTPUBAGDB' TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.$(Sub1InsName)\MSSQL\DATA\$(SubDb).mdf',  
MOVE N'TESTPUBAGDB_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.$(Sub1InsName)\MSSQL\DATA\$(SubDb)_log.ldf',  
RECOVERY,  NOUNLOAD,  STATS = 5;
GO
 
 
 
:Connect $(NodeSub1)
BACKUP DATABASE $(SubDB) TO  DISK = N'$(BackupShare)$(SubDB).bak' 
WITH NOFORMAT, INIT,  NAME = N'$(SubDB)-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10;
GO
 
BACKUP LOG $(SubDB) TO  DISK = N'$(BackupShare)$(SubDB)_log.trn' 
WITH NOFORMAT, INIT,  NAME = N'$(SubDB)-Log Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10;
GO
ALTER AVAILABILITY GROUP $(AGSubName) ADD DATABASE $(SubDB);  
GO
 
:Connect $(NodeSub2)
RESTORE DATABASE $(SubDB) FROM DISK = N'$(BackupShare)$(SubDB).bak'  WITH NORECOVERY, stats=10;
GO
RESTORE LOG $(SubDB) FROM DISK = N'$(BackupShare)$(SubDB)_log.trn'  WITH NORECOVERY, stats=10;
GO
 
ALTER DATABASE $(SubDB) SET HADR AVAILABILITY GROUP = $(AGSubName);
GO
 
 
 
 
/*
***************************************************************************
*******>Finalize Config by Starting Snapshot then test with tracer <*******
***************************************************************************
*/
 
:CONNECT $(NodePub1)
 
USE $(AGPubDatabase)
 
DECLARE @publicationname varchar(2000)
SET @publicationname = (SELECT name FROM dbo.syspublications)
 
EXEC sp_startpublication_snapshot @publication=@publicationname;
GO
 
 
--Then do a tracer token test through Replication Monitor. Did it work? If so, you're good! Please note you'll need to connect to the primary of the publisher to do this, or you can call the manual procs as discussed https://docs.microsoft.com/en-us/sql/relational-databases/replication/monitor/measure-latency-and-validate-connections-for-transactional-replication?view=sql-server-ver15
