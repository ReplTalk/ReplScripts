-- This script generates fn_getConnectionString, fn_getConnectionString functions and sp_printResult procedure then deletes the generated functions and procs at the end
-- Make sure these functions and procs dont exist previously in the database where the script is going to run else those functions and procs would be dropped
-- If any of the functions or procs exists in the DB where the script executed then rename the above mentioned functions or procs

-- In case a failover happened and the new replica becomes primary script needs to be regnerated speciying the new repica as primary

/* IMP : After creating the publication from UI add Multisubnetfailover property and set its value to 1 in the log reader agent
         in case nodes are in multiple subnet */

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

declare @pubAGName sysname, @pubListenerName sysname, 
		@pubListenerPort sysname, @pubEndpointPort sysnamE, @nodeDomainName sysname,
		@distAdminLoginPassword sysname, @pubDatabase sysname, @backupSharePath sysname, @replDirPath sysname,
		@primaryDistNodeName sysname,  @primaryDistInsName sysname, @originalPublisher sysname, @distDatabaseName sysname,
		@distAgListener sysname

set @pubEndpointPort = '5023'
set @nodeDomainName = 'corp.contoso.com'
set @pubAGName = 'PubAg'
set @pubListenerPort = '6023'
set @pubListenerName = 'PubAGListener'
set @backupSharePath = '\\SQL-VM-1\share_folder'
set @replDirPath = '\\SQL-VM-1\share_folder'
set @distAdminLoginPassword = 'Yukon900yukon900'
set @pubDatabase = 'TESTPUBAGDB'
set @primaryDistNodeName = 'SQL-VM-2'			-- If distributor is not in AG then provide NodeName of the single distributor
set @primaryDistInsName = 'SQL20191'		-- If distributor is not in AG then provide InstanceName of the single distributor
set @distDatabaseName = 'distributiondb'
set @distAgListener = 'DistDbList'		-- If distributor is not in AG then provide {ServerName}\{InstanceName} of the single distributor

-- Publisher Node details
DECLARE @publisherNodes TABLE
(nodeName sysname, 
 insName sysname, 
 isPrimary bit,		-- 1 if the replica is primary else 0
 sqlAcctName sysname
)

-- Distributor Node details
DECLARE @distributorNodes TABLE
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
--sqlAcctName should be in this format domainName\userName
-- Example fareast\xyz

insert into @publisherNodes values('SQL-VM-1', 'SQL20192', 0, 'corp\sqlsvc1')
insert into @publisherNodes values('SQL-VM-2', 'SQL20192', 1, 'corp\sqlsvc1')

insert into @distributorNodes values('SQL-VM-1', 'SQL20191')
insert into @distributorNodes values('SQL-VM-2', 'SQL20191')

-- Need to add the listener IP details here
insert into @listenerIPDetails values('10.1.1.16', '255.255.255.0')
insert into @listenerIPDetails values('10.1.2.16', '255.255.255.0')

-- Variables to determine whether to generate setup/cleanup/both script
declare @generateScript sysname

-- The value of generateScript should be setup/cleanup/both depending on what scripts we are going to generate
-- In case you get the exception or want to cleanup the created setup of AG, generate the cleanup part of script and run it
-- NOTE : While generating the cleanup script make sure that the primary replica node names are correctly updated in the variable section
set @generateScript = 'cleanup'

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
select @primaryNodeName = nodeName, @primaryInsName = insName from @publisherNodes where isPrimary = 1

-- Declaring variables used by the script
declare @sqlAcctName sysname
declare @currNodeName sysname
declare @currInsName sysname
declare @connectionString sysname
declare @currSubnetMask sysname
declare @currIPAddress sysname

-- Number of nodes in the publisher AG
declare @numNodes int
select @numNodes = count(*) from  @publisherNodes

-- Check whther publisher AG is in single subnet or in multiple subnets
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

if (@numNodes > 1)
begin

-- Scripting creation of endpoint and xevents

declare sqlServerDetails_cursor cursor for
select nodeName, insName from @publisherNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'IF NOT EXISTS(select * from sys.endpoints where name = ''Hadr_endpoint'')
BEGIN
	CREATE ENDPOINT [Hadr_endpoint]
	STATE = STARTED
	AS TCP (LISTENER_PORT = ' + @pubEndpointPort +')
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

-- Confiure the remote login timeout to 60 seconds in the distributor nodes if publisher AG has nodes in multiple subnet

if (@isMultiSubnet = 1)
begin
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @distributorNodes
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

set @result = @result + dbo.fn_getConnectionString(@primaryNodeName, @primaryInsName) + 'IF NOT EXISTS(select * from sys.availability_groups where name = ''' + @pubAGName + ''')
BEGIN
	CREATE AVAILABILITY GROUP ' +  @pubAGName + ' FOR REPLICA ON ' + CHAR(13)
declare sqlServerDetails_cursor cursor for
select nodeName, insName from @publisherNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	set @result = @result + CHAR(9) + '''' + dbo.fn_getSqlSeverInstanceName(@currNodeName, @currInsName) +  ''' WITH
	(
	ENDPOINT_URL = ''TCP://' + @currNodeName + '.' + @nodeDomainName + ':' + @pubEndpointPort + ''',
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
'IF NOT EXISTS(select * from sys.availability_group_listeners where group_id = (select group_id from sys.availability_groups where name = ''' + @pubAGName + '''))
BEGIN
	ALTER AVAILABILITY GROUP ' +  @pubAGName + '
	ADD LISTENER ''' + @pubListenerName + ''' (
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
	, PORT=' + @pubListenerPort + ')
END' + CHAR(13) + 'go' + CHAR(13)
set @result = @result + 'print ''Listener of the AG has been created''' + CHAR(13) + CHAR(13)

-- Making all the replicas part of AG

declare sqlServerDetails_cursor cursor for
select nodeName, insName from @publisherNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	If (NOT(@currNodeName = @primaryNodeName AND @currInsName = @primaryInsName))
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) + 
'IF NOT EXISTS(select * from sys.availability_groups where name = ''' + @pubAGName + ''')
BEGIN
	ALTER AVAILABILITY GROUP ' + @pubAGName + ' JOIN
	ALTER AVAILABILITY GROUP ' + @pubAGName + ' GRANT CREATE ANY DATABASE
END' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
	END
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor
set @result = @result + 'print ''All the secondary replicas joined the AG''' + CHAR(13) + CHAR(13)

-- Add 32 and 64 bit alias in the distributor nodes if publisher AG listener is running on a non-default port. Default port is 1433
if (@pubListenerPort != '1433')
begin
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @distributorNodes
	open sqlServerDetails_cursor
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'exec dbo.xp_regwrite @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @pubListenerName + ''', @type = ''REG_SZ'',
		@value = ''DBMSSOCN,' + @pubListenerName + ',' + @pubListenerPort + '''
exec dbo.xp_regwrite @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @pubListenerName + ''', @type = ''REG_SZ'',
		@value = ''DBMSSOCN,' + @pubListenerName + ',' + @pubListenerPort + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	END
	ClOSE sqlServerDetails_cursor
	DEALLOCATE sqlServerDetails_cursor
end

-- Set the recovery of publisher db to full if not already set
-- Backup the publisher db
-- Add the publisher db to the AG
-- Configure log and full backups on publisher db so as to truncate the logs (Needs to be done by end user)
set @result = @result + dbo.fn_getConnectionString(@primaryNodeName, @primaryInsName) +
'ALTER DATABASE ' + @pubDatabase + ' SET RECOVERY FULL
BACKUP DATABASE ' + @pubDatabase + ' TO  DISK = ''' + @backupSharePath + '\' + @pubDatabase + '.bak''
ALTER AVAILABILITY GROUP ' + @pubAGName + ' ADD DATABASE ' + @pubDatabase + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
set @result = @result + 'print ''Added publisher db to the availability group''' + CHAR(13) + CHAR(13)

end -- Ending the if(@numNodes > 1) check

-- Add publishers in the primary distributor replica

set @result = @result + dbo.fn_getConnectionString(@primaryDistNodeName, @primaryDistInsName)
declare sqlServerDetails_cursor cursor for
select nodeName, insName from @publisherNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	set @sqlServerInstName = dbo.fn_getSqlSeverInstanceName(@currNodeName, @currInsName) 
	set @result = @result + 
'IF NOT EXISTS(select * from msdb..MSdistpublishers where name = ''' + @sqlServerInstName + ''')
	exec sys.sp_adddistpublisher @publisher = ''' + @sqlServerInstName + ''', @distribution_db = ''' + @distDatabaseName + ''', @working_directory = ''' + @replDirPath + '''' + CHAR(13) + CHAR(13)
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor
set @result = @result + 'go' + CHAR(13)
set @result = @result + 'print ''Added publishers in the primary replica of distributor''' + CHAR(13) + CHAR(13)

-- Add publishers in the secondary distributor replicas
declare @publisherCurrNodeName sysname, @publisherCurrInsName sysname

declare sqlServerDetails_cursor cursor for
select nodeName, insName from @distributorNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	If (NOT(@currNodeName = @primaryDistNodeName AND @currInsName = @primaryDistInsName))
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName)
		declare sqlServerPublisherDetails_cursor cursor for
		select nodeName, insName from @publisherNodes
		open sqlServerPublisherDetails_cursor
		fetch next from sqlServerPublisherDetails_cursor into @publisherCurrNodeName, @publisherCurrInsName
		WHILE @@FETCH_STATUS = 0
		BEGIN
			set @sqlServerInstName = dbo.fn_getSqlSeverInstanceName(@publisherCurrNodeName, @publisherCurrInsName)
			set @result = @result + 
'IF NOT EXISTS(select * from msdb..MSdistpublishers where name = ''' + @sqlServerInstName + ''')
	exec sys.sp_adddistpublisher @publisher = ''' + @sqlServerInstName + ''', @distribution_db = ''' + @distDatabaseName + ''', @working_directory = ''' + @replDirPath + '''' + CHAR(13) + CHAR(13)
		fetch next from sqlServerPublisherDetails_cursor into @publisherCurrNodeName, @publisherCurrInsName
		END
		ClOSE sqlServerPublisherDetails_cursor
		DEALLOCATE sqlServerPublisherDetails_cursor
		set @result = @result + 'go' + CHAR(13)
	END
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor
set @result = @result + 'print ''Added publisher in all the secondary replicas of distributor''' + CHAR(13) + CHAR(13)

-- Add distributor for all the publisher replicas
declare sqlServerDetails_cursor cursor for
select nodeName, insName from @publisherNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) + 
'IF NOT EXISTS(select * from sys.sysservers where dist = 1)
	exec sp_adddistributor @distributor= ' + @distAgListener + ', @password= ''' + @distAdminLoginPassword + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor
set @result = @result + 'print ''Added distributor for all the publisher replicas''' + CHAR(13) + CHAR(13)

-- Add the redirect publisher entry in the distribution db of primary distributor
-- Assuming that the primary publisher replica mentioned in the script input is the one creating publication
if(@numNodes > 1)
begin
	set @originalPublisher = dbo.fn_getSqlSeverInstanceName(@primaryNodeName, @primaryInsName)
	set @result = @result + dbo.fn_getConnectionString(@primaryDistNodeName, @primaryDistInsName) +
'use [' + @distDatabaseName + ']
exec sys.sp_redirect_publisher @original_publisher = ''' + @originalPublisher + ''', @publisher_db = ''' + @pubDatabase + ''', @redirected_publisher = ''' + @pubListenerName + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
set @result = @result + 'print ''Added redirect publisher entry in the distribution db of primary distributor''' + CHAR(13) + CHAR(13)
end

set @result = @result + 'print ''''' + CHAR(13)
set @result = @result + 'print ''NOTE : NOW YOU CREATE PUBLICATION ON PUBLISHER DB''' + CHAR(13) + CHAR(13)


-- Ending of setup script
set @result = @result + '-- Ending of setup script' + CHAR(13) + CHAR(13)

cleanup:
if (@generateScript =  'setup')
goto printResult

--Starting of cleanup script
set @result = @result + '-- Starting of cleanup script' + CHAR(13) + CHAR(13)

set @result = @result + '-- Drop all the publications and subscriptions if created before executing the cleanup script' + CHAR(13) + CHAR(13)

-- Scripting condition to exit in case of errors
set @result = @result + ':On error exit' + CHAR(13) + CHAR(13)

-- Drop the availability group
if(@numNodes > 1)
begin
	set @result = @result + dbo.fn_getConnectionString(@primaryNodeName, @primaryInsName) + 'IF EXISTS(select * from sys.availability_groups where name = ''' + @pubAGName + ''')
	DROP AVAILABILITY GROUP ' + @pubAGName + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
end

-- Drop the distributors for all the publisher replicas
declare sqlServerDetails_cursor cursor for
select nodeName, insName from @publisherNodes
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

-- Drop the publishers if exists on secondary distributor replicas
declare sqlServerDetails_cursor cursor for
select nodeName, insName from @distributorNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	If (NOT(@currNodeName = @primaryDistNodeName AND @currInsName = @primaryDistInsName))
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName)
		declare sqlServerPublisherDetails_cursor cursor for
		select nodeName, insName from @publisherNodes
		open sqlServerPublisherDetails_cursor
		fetch next from sqlServerPublisherDetails_cursor into @publisherCurrNodeName, @publisherCurrInsName
		set @result = @result +
'IF object_id(''msdb..MSdistpublishers'') is not null
BEGIN' + CHAR(13)
		WHILE @@FETCH_STATUS = 0
		BEGIN
			set @sqlServerInstName = dbo.fn_getSqlSeverInstanceName(@publisherCurrNodeName, @publisherCurrInsName)
			set @result = @result +
	'IF EXISTS(select * from msdb..MSdistpublishers where name = ''' + @sqlServerInstName + ''')
		exec sys.sp_dropdistpublisher @publisher = ''' + @sqlServerInstName + ''', @no_checks = 1;' + CHAR(13) + CHAR(13)
		fetch next from sqlServerPublisherDetails_cursor into @publisherCurrNodeName, @publisherCurrInsName
		END
		ClOSE sqlServerPublisherDetails_cursor
		DEALLOCATE sqlServerPublisherDetails_cursor
		set @result = @result + 'END' + CHAR(13) + 'go' + CHAR(13)
	END
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor

-- Drop the publishers if exists on primary distributor replica
set @result = @result + dbo.fn_getConnectionString(@primaryDistNodeName, @primaryDistInsName)
declare sqlServerDetails_cursor cursor for
select nodeName, insName from @publisherNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
		set @result = @result +
'IF object_id(''msdb..MSdistpublishers'') is not null
BEGIN' + CHAR(13)
WHILE @@FETCH_STATUS = 0
BEGIN
	set @sqlServerInstName = dbo.fn_getSqlSeverInstanceName(@currNodeName, @currInsName)
	set @result = @result +
	'IF EXISTS(select * from msdb..MSdistpublishers where name = ''' + @sqlServerInstName + ''')
		exec sys.sp_dropdistpublisher @publisher = ''' + @sqlServerInstName + '''' + CHAR(13) + CHAR(13)
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor
set @result = @result + 'END' + CHAR(13) + 'go' + CHAR(13)

if(@numNodes > 1)
begin

-- Drop the alias on the distributor nodes if created
if (@pubListenerPort != '1433')
begin
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @distributorNodes
	open sqlServerDetails_cursor
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'exec dbo.xp_regdeletevalue @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @pubListenerName + '''
exec dbo.xp_regdeletevalue @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @pubListenerName + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	END
	ClOSE sqlServerDetails_cursor
	DEALLOCATE sqlServerDetails_cursor
end

-- Restore all the primary and subscriber databases
declare sqlServerDetails_cursor cursor for
select nodeName, insName from @publisherNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) + 
'IF EXISTS(select * from sys.databases where name = ''' + @pubDatabase + ''' and state_desc = ''RESTORING'')
BEGIN
	RESTORE DATABASE ' + @pubDatabase + ' WITH RECOVERY
END' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor

end	-- Ending the if(@numNodes > 1) check

-- Ending of cleanup script
set @result = @result + 'print ''NOTE : PUBLISHER DATABASES ARE PRESENT ON BOTH PRIMARY AND SECONDARY REPLICAS. YOU CAN DELETE THEM IF NOT NEEDED''' + CHAR(13)
set @result = @result + '-- Ending of cleanup script' + CHAR(13)

printResult:
-- Drop the created functions
drop function fn_getConnectionString
drop function fn_getSqlSeverInstanceName


exec sp_printResult @result

/* ************************************************************************
   ************************************************************************ */