-- This script generates fn_getConnectionString, fn_getConnectionString functions and sp_printResult procedure then deletes the generated functions and procs at the end
-- Make sure these functions and procs dont exist previously in the database where the script is going to run else those functions and procs would be dropped
-- If any of the functions or procs exists in the DB where the script executed then rename the above mentioned functions or procs

-- If distributor is not in AG then no need to use this script simply use the UI to create distributor

-- In case a failover happened and the new replica becomes primary script needs to be regnerated speciying the new repica as primary

set nocount on

/* ************************************************************************
   ************************************************************************
					FUNCTIONS/PROCS USED BY THE SCRIPT						*/

if object_id('fn_getConnectionString', 'FN') is not null
drop function fn_getConnectionString
go

--Function to give the connection string
create function fn_getConnectionString
(
	@nodeName sysname,
	@insName sysname
)
returns sysname
as
begin
	declare @connectionString sysname = ''
	set @connectionString = @connectionString + ':Connect ' + @nodeName
	if (@insName != 'MSSQLSERVER')
	begin
		set @connectionString = @connectionString + '\' + @insName
	end
	set @connectionString = @connectionString + CHAR(13) + CHAR(13)
	return @connectionString
end
go

if object_id('fn_getSqlSeverInstanceName', 'FN') is not null
drop function fn_getSqlSeverInstanceName
go

--Function to give the sql server Instance Name
create function fn_getSqlSeverInstanceName
(
	@nodeName sysname,
	@insName sysname
)
returns sysname
as
begin
	declare @instanceWithNodeName sysname = ''
	set @instanceWithNodeName = @instanceWithNodeName  + @nodeName
	if (@insName != 'MSSQLSERVER')
	set @instanceWithNodeName = @instanceWithNodeName + '\' + @insName
	return @instanceWithNodeName
end
go

if object_id('sp_printResult', 'P') is not null
drop procedure sp_printResult
go

-- Procedure to print the result
-- Currently print function can only print 8000 bytes.
-- Splitting a large string into substring of 8000 bytes and then printing it
create procedure sp_printResult
(
	@result nvarchar(max)
)
as
begin
	DECLARE @CurrentEnd BIGINT, /* track the length of the next substring */               @offset tinyint /*tracks the amount of offset needed */
	set @result = replace(  replace(@result, char(13) + char(10), char(10)), char(13), char(10))
	WHILE LEN(@result) > 1
	BEGIN       
		IF CHARINDEX(CHAR(10), @result) between 1 AND 4000
		BEGIN
           SET @CurrentEnd =  CHARINDEX(char(10), @result) -1
           set @offset = 2
		END
		ELSE
		BEGIN
           SET @CurrentEnd = 4000
            set @offset = 1
		END   
		PRINT SUBSTRING(@result, 1, @CurrentEnd)                                              
		set @result = SUBSTRING(@result, @CurrentEnd+@offset, 1073741822)        
	END /*End While loop*/
end
go

/* ************************************************************************
   ************************************************************************ */

/* ************************************************************************
   ************************************************************************
					VARIABLES VALUES THAT NEEDS TO BE SET					 */

declare @distAGName sysname, @distListenerName sysname,
		@distListenerPort sysname, @distEndpointPort sysnamE, @nodeDomainName sysname,
		@distAdminLoginPassword sysname, @distDatabaseName sysname, @backupSharePath sysname, @replDirPath sysname

set @distEndpointPort = '5022'
set @nodeDomainName = 'corp.contoso.com'
set @distAGName = 'DistributionDBAg'
set @distListenerPort = '6022'
set @distListenerName = 'DistDbList'
set @backupSharePath = '\\SQL-VM-1\share_folder'
set @replDirPath = '\\SQL-VM-1\share_folder'
set @distDatabaseName = 'distributiondb'
set @distAdminLoginPassword = 'Yukon900yukon900'

-- Distributor Node details
DECLARE @distributorNodes TABLE
(nodeName sysname, 
 insName sysname, 
 isPrimary bit,		-- 1 if the replica is primary else 0
 sqlAcctName sysname
)

-- If publisher will not be in AG then also it will not matter
-- Publisher Node details
DECLARE @publisherNodes TABLE
(nodeName sysname, 
 insName sysname
)

-- listener IP Details
-- If the AG has nodes in different subnet then we need to specify an ip from each of the subnet in listnerIPDetails
DECLARE @listenerIPDetails TABLE
(
	IPAddress sysname,
	subnetMask sysname
)

--sqlAcctName should be in this format {domainName}\{userName}
-- Example fareast\xyz

-- Need to add the distributor nodes details here
insert into @distributorNodes values('SQL-VM-1', 'SQL20191', 0, 'corp\sqlsvc1')
insert into @distributorNodes values('SQL-VM-2', 'SQL20191', 1, 'corp\sqlsvc1')

-- Need to add the publihser nodes details here
insert into @publisherNodes values('SQL-VM-1', 'SQL20192')
insert into @publisherNodes values('SQL-VM-2', 'SQL20192')

-- Need to add the listener IP details here
insert into @listenerIPDetails values('10.1.1.15', '255.255.255.0')
insert into @listenerIPDetails values('10.1.2.15', '255.255.255.0')

-- Variables to determine whether to generate setup/cleanup script
declare @generateScript sysname

-- The value of generateScript should be setup/cleanup/both depending on what scripts we are going to generate
-- In case you get the exception or want to cleanup the created setup of AG, generate the cleanup part of script and run it
-- NOTE : While generating the cleanup script make sure that the primary replica node names are correctly updated in the variable section
set @generateScript = 'setup'

/* ************************************************************************
   ************************************************************************ */

/* ************************************************************************
   ************************************************************************
			DO NOT MODIFY THE VALUES OF VARIABLES OF THE BELOW SECTION 
			BELOW SECTION CONTAINS THE SCRIPTING LOGIC                      */

-- declaring result which will contain the final script
declare @result nvarchar(max) = ''
declare @sqlServerInstName sysname

-- Fetching the primary node details
declare @primaryNodeName sysname
declare @primaryInsName sysname
select @primaryNodeName = nodeName, @primaryInsName = insName from @distributorNodes where isPrimary = 1

-- Declaring variables used by the script
declare @sqlAcctName sysname
declare @currNodeName sysname
declare @currInsName sysname
declare @connectionString sysname
declare @currSubnetMask sysname
declare @currIPAddress sysname

-- Check whether distributor AG is in single subnet or in multiple subnets
declare @isMultiSubnet bit = 0
declare @numOfIpsInListenerDetails int
select @numOfIpsInListenerDetails = COUNT(*) from @listenerIPDetails
if (@numOfIpsInListenerDetails > 1)
	set @isMultiSubnet = 1;

if (@generateScript = 'cleanup')
goto cleanup

--Starting of setup script
set @result = @result + '-- Starting of setup script' + CHAR(13) + CHAR(13)

-- Scripting condition to exit in case of errors
set @result = @result + ':On error exit' + CHAR(13) + CHAR(13)

-- Scripting creation of endpoint and xevents

declare sqlServerDetails_cursor cursor for
select nodeName, insName from @distributorNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'IF NOT EXISTS(select * from sys.endpoints where name = ''Hadr_endpoint'')
BEGIN
	CREATE ENDPOINT [Hadr_endpoint]
	STATE = STARTED
	AS TCP (LISTENER_PORT = ' + @distEndpointPort +')
	FOR DATA_MIRRORING (ROLE = ALL)
END
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name=''AlwaysOn_health'')
BEGIN
  ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON);
END
IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE name=''AlwaysOn_health'')
BEGIN
  ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START;
END' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor
set @result = @result + 'print ''Endpoint and xevent sessions created in all the replicas''' + CHAR(13) + CHAR(13)

 -- Confiure the remote login timeout to 60 seconds in the publisher nodes if distributor AG has nodes in multiple subnet

if (@isMultiSubnet = 1)
begin
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @publisherNodes
	open sqlServerDetails_cursor
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'exec sp_configure ''remote login timeout (s)'', 60
reconfigure' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	END
	ClOSE sqlServerDetails_cursor
	DEALLOCATE sqlServerDetails_cursor
end

-- Create AG

set @result = @result + dbo.fn_getConnectionString(@primaryNodeName, @primaryInsName) + 'IF NOT EXISTS(select * from sys.availability_groups where name = ''' + @distAGName + ''')
BEGIN
	CREATE AVAILABILITY GROUP ' +  @distAGName + ' FOR REPLICA ON ' + CHAR(13)
declare sqlServerDetails_cursor cursor for
select nodeName, insName from @distributorNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	set @result = @result + CHAR(9) + '''' + dbo.fn_getSqlSeverInstanceName(@currNodeName, @currInsName) +  ''' WITH
	(
	ENDPOINT_URL = ''TCP://' + @currNodeName + '.' + @nodeDomainName + ':' + @distEndpointPort + ''',
	FAILOVER_MODE = AUTOMATIC,
	AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
	BACKUP_PRIORITY = 50, 
	SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL),
	SEEDING_MODE = AUTOMATIC),' + CHAR(13)
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor
set @result = SUBSTRING(@result, 1, LEN(@result)-2) + CHAR(13) + 'END' + CHAR(13) + 'print ''Availability group has been successfully created''' + CHAR(13) + CHAR(13)

-- Create AG listener

set @result = @result +
'IF NOT EXISTS(select * from sys.availability_group_listeners where group_id = (select group_id from sys.availability_groups where name = ''' + @distAGName + '''))
BEGIN
	ALTER AVAILABILITY GROUP ' +  @distAGName + '
	ADD LISTENER ''' + @distListenerName + ''' (
	WITH IP
	('

-- Adding all the listener ips
declare listenerDetails_cursor cursor for
select IPAddress, subnetMask from @listenerIPDetails
open listenerDetails_cursor
fetch next from listenerDetails_cursor into @currIPAddress, @currSubnetMask
WHILE @@FETCH_STATUS = 0
BEGIN
	set @result = @result + '
	(''' + @currIPAddress + ''', ''' + @currSubnetMask + '''),'
	fetch next from listenerDetails_cursor into @currIPAddress, @currSubnetMask
END
ClOSE listenerDetails_cursor
DEALLOCATE listenerDetails_cursor

set @result = SUBSTRING(@result, 1, LEN(@result)-1) +
	')
	, PORT=' + @distListenerPort + ')
END' + CHAR(13) + 'go' + CHAR(13)
set @result = @result + 'print ''Listener of the AG has been created''' + CHAR(13) + CHAR(13)


-- Making all the replicas part of AG

declare sqlServerDetails_cursor cursor for
select nodeName, insName from @distributorNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	If (NOT(@currNodeName = @primaryNodeName AND @currInsName = @primaryInsName))
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) + 
'IF NOT EXISTS(select * from sys.availability_groups where name = ''' + @distAGName + ''')
BEGIN
	ALTER AVAILABILITY GROUP ' + @distAGName + ' JOIN
	ALTER AVAILABILITY GROUP ' + @distAGName + ' GRANT CREATE ANY DATABASE
END' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
	END
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor
set @result = @result + 'print ''All the secondary replicas joined the AG''' + CHAR(13) + CHAR(13)

-- Add 32 and 64 bit alias in the distributor nodes if distributor AG listener is running on a non-default port. Default port is 1433
if (@distListenerPort != '1433')
begin
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @distributorNodes
	open sqlServerDetails_cursor
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'exec dbo.xp_regwrite @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @distListenerName + ''', @type = ''REG_SZ'',
		@value = ''DBMSSOCN,' + @distListenerName + ',' + @distListenerPort + '''
exec dbo.xp_regwrite @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @distListenerName + ''', @type = ''REG_SZ'',
		@value = ''DBMSSOCN,' + @distListenerName + ',' + @distListenerPort + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	END
	ClOSE sqlServerDetails_cursor
	DEALLOCATE sqlServerDetails_cursor
end

-- Add 32 and 64 bit alias in the publisher nodes if distributor AG listener is running on a non-default port. Default port is 1433
if (@distListenerPort != '1433')
begin
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @publisherNodes
	open sqlServerDetails_cursor
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'exec dbo.xp_regwrite @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @distListenerName + ''', @type = ''REG_SZ'',
		@value = ''DBMSSOCN,' + @distListenerName + ',' + @distListenerPort + '''
exec dbo.xp_regwrite @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @distListenerName + ''', @type = ''REG_SZ'',
		@value = ''DBMSSOCN,' + @distListenerName + ',' + @distListenerPort + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	END
	ClOSE sqlServerDetails_cursor
	DEALLOCATE sqlServerDetails_cursor
end

-- Add distributor in all the replicas
declare sqlServerDetails_cursor cursor for
select nodeName, insName from @distributorNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) + 
'IF NOT EXISTS(select * from sys.sysservers where dist = 1)
	exec sp_adddistributor @distributor= @@servername, @password= ''' + @distAdminLoginPassword + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor
set @result = @result + 'print ''Added distributor for all the replicas''' + CHAR(13) + CHAR(13)

-- Add distribution db in the primary replica
set @result = @result + dbo.fn_getConnectionString(@primaryNodeName, @primaryInsName) +
'IF NOT EXISTS(select * from msdb.dbo.MSdistributiondbs where name = ''' + @distDatabaseName + ''' )
BEGIN
	exec sp_adddistributiondb @database = ''' + @distDatabaseName + ''', @security_mode = 1
END' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
set @result = @result + 'print ''Added distribution db in the primary distributor replica''' + CHAR(13) + CHAR(13)

-- Set the recovery of distribution db to full
-- Backup the distribution db
-- Add the distribution db to the AG
set @result = @result + dbo.fn_getConnectionString(@primaryNodeName, @primaryInsName) +
'IF EXISTS(select * from msdb.dbo.MSdistributiondbs where name = ''' + @distDatabaseName + ''' )
BEGIN
	ALTER DATABASE ' + @distDatabaseName + ' SET RECOVERY FULL
	BACKUP DATABASE ' + @distDatabaseName + ' TO  DISK = ''' + @backupSharePath + '\' + @distDatabaseName + '.bak''
	ALTER AVAILABILITY GROUP ' + @distAGName + ' ADD DATABASE ' + @distDatabaseName + '
END' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
set @result = @result + 'print ''Added distribution db to the availability group''' + CHAR(13) + CHAR(13)

-- Configure log and full backups on distribution db so as to truncate the logs

-- Make sure that the distribution Db is synchronized across the replicas
-- Sleep for 2 secs and then again check whether the distribution database is synchronized
set @result = @result + dbo.fn_getConnectionString(@primaryNodeName, @primaryInsName) +
'declare @databaseid sysname
select @databaseid = database_id from sys.databases where name = ''' + @distDatabaseName + '''
WHILE 1 = 1
begin
	if exists(select * from  sys.dm_hadr_database_replica_states where database_id = @databaseid  and synchronization_state_desc != ''SYNCHRONIZED'')
		WAITFOR DELAY ''00:00:02.000''
	else
		break
end' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)

-- Need to make sure that the distribution db is secondary replicas are in sync till we execute the below queries
-- Add distribution db in the secondary replicas
-- TODO: Need to check the seeeding DMV whether distribution db is synchronised in the secondary replicas 

declare sqlServerDetails_cursor cursor for
select nodeName, insName from @distributorNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	If (NOT(@currNodeName = @primaryNodeName AND @currInsName = @primaryInsName))
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'IF NOT EXISTS(select * from msdb.dbo.MSdistributiondbs where name = ''' + @distDatabaseName + ''')
	exec sp_adddistributiondb @database = ''' + @distDatabaseName + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
	END
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor
set @result = @result + 'print ''Added distribution db in all the secondary replicas''' + CHAR(13) + CHAR(13)

-- Ending of setup script
set @result = @result + '-- Ending of setup script' + CHAR(13) + CHAR(13)

cleanup:
if (@generateScript =  'setup')
goto printResult

--Starting of cleanup script
set @result = @result + '-- Starting of cleanup script' + CHAR(13) + CHAR(13)

-- Scripting condition to exit in case of errors
set @result = @result + ':On error exit' + CHAR(13) + CHAR(13)

-- Drop the availability group
set @result = @result + dbo.fn_getConnectionString(@primaryNodeName, @primaryInsName) + 'IF EXISTS(select * from sys.availability_groups where name = ''' + @distAGName + ''')
	DROP AVAILABILITY GROUP ' + @distAGName + CHAR(13) + 'go' + CHAR(13) + CHAR(13)

-- Restore the database distribution with recovery
-- Drop the distribution db
declare sqlServerDetails_cursor cursor for
select nodeName, insName from @distributorNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	If (NOT(@currNodeName = @primaryNodeName AND @currInsName = @primaryInsName))
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'IF object_id(''msdb.dbo.MSdistributiondbs'') is not null
BEGIN
	IF EXISTS(select * from msdb.dbo.MSdistributiondbs where name = ''' + @distDatabaseName + ''')
	BEGIN
		RESTORE DATABASE ' + @distDatabaseName + ' WITH RECOVERY, KEEP_REPLICATION
		exec sys.sp_dropdistributiondb @database = ''' + @distDatabaseName + ''' , @former_ag_secondary = 1
	END
END' +CHAR(13) + 'go' + CHAR(13) + CHAR(13)
	END
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor

--Drop the distribution db on the primary replica
set @result = @result + dbo.fn_getConnectionString(@primaryNodeName, @primaryInsName) + 
'IF object_id(''msdb.dbo.MSdistributiondbs'') is not null
BEGIN
	IF EXISTS(select * from msdb.dbo.MSdistributiondbs where name = ''' + @distDatabaseName + ''')
		exec sys.sp_dropdistributiondb @database = ''' + @distDatabaseName + ''' 
END' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)

-- Drop the distributors
declare sqlServerDetails_cursor cursor for
select nodeName, insName from @distributorNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) + 
'IF EXISTS(select * from sys.sysservers where dist = 1)
	exec sp_dropdistributor' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor

-- Drop the alias on the distributor nodes if created
if (@distListenerPort != '1433')
begin
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @distributorNodes
	open sqlServerDetails_cursor
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'exec dbo.xp_regdeletevalue @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'',
  @value_name = ''' + @distListenerName + '''
exec dbo.xp_regdeletevalue @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo'',
  @value_name = ''' + @distListenerName + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	END
	ClOSE sqlServerDetails_cursor
	DEALLOCATE sqlServerDetails_cursor
end

-- Drop the alias on the publisher nodes if created
if (@distListenerPort != '1433')
begin
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @publisherNodes
	open sqlServerDetails_cursor
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'exec dbo.xp_regdeletevalue @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @distListenerName + '''
exec dbo.xp_regdeletevalue @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @distListenerName + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	END
	ClOSE sqlServerDetails_cursor
	DEALLOCATE sqlServerDetails_cursor
end

-- Ending of cleanup script
set @result = @result + '-- Ending of cleanup script' + CHAR(13)

printResult:
-- Drop the created functions
drop function fn_getConnectionString
drop function fn_getSqlSeverInstanceName

exec sp_printResult @result

/* ************************************************************************
   ************************************************************************ */