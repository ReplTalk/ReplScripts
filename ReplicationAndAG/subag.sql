-- This script generates fn_getConnectionString, fn_getConnectionString functions and sp_printResult procedure then deletes the generated functions and procs at the end
-- Make sure these functions and procs dont exist previously in the database where the script is going to run else those functions and procs would be dropped
-- If any of the functions or procs exists in the DB where the script executed then rename the above mentioned functions or procs

-- In case a failover happened and the new replica becomes primary script needs to be regnerated speciying the new repica as primary

/* IMP : After distribution agent is created add Multisubnetfailover property in distribution agent and set its value to 1
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

declare @subAGName sysname, @subListenerName sysname,
		@subListenerPort sysname, @subEndpointPort sysnamE, @nodeDomainName sysname,
		@subDatabase sysname, @backupSharePath sysname, @primaryPublisherNodeName sysname, 
		@primaryPublisherInsName sysname, @subscriptionType varchar(5), @publicationName sysname, 
		@pubDatabase sysname,  --pubDatabase is required only if subscription is push
		@distAGName sysname, @distListenerName sysname, @distListenerPort sysname,
		@originalPublisherNodeName sysname, @originalPublisherInsName sysname, -- Original Publisher details are the replica where the publication was intially created
		@generateScript sysname

-- Subscriber Node details
DECLARE @subscriberNodes TABLE
(nodeName sysname, 
 insName sysname, 
 isPrimary bit,		-- 1 if the replica is primary else 0
 sqlAcctName sysname
)

-- Publisher Nodes details
DECLARE @publisherNodes TABLE
(nodeName sysname, 
 insName sysname
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

-- subscriptionType will be either 'push' or 'pull'. Depending on the type of subscription script for push or pull subscription will be generated.

set @subEndpointPort = '5024'
set @nodeDomainName = 'corp.contoso.com'
set @subAGName = 'SubAg'				-- If subscriber is not in AG then provide {ServerName}\{InstanceName} of the single subscriber
set @subListenerPort = '6024'
set @subListenerName = 'SubAGListener'
set @backupSharePath = '\\SQL-VM-1\share_folder'
set @subDatabase = 'TESTPUBAGDB_Sub'
set @primaryPublisherNodeName = 'SQL-VM-1'		-- In case of single publisher provide node name of single publisher
set @primaryPublisherInsName = 'SQL20192'	-- In case of single publisher provide instance name of single publisher
set @publicationName = 'publi'
set @subscriptionType = 'pull'
set @pubDatabase = 'TESTPUBAGDB'
set @originalPublisherNodeName = 'SQL-VM-2'
set @originalPublisherInsName = 'SQL20192'

-- Require these details if subscription is of pull type and distributor is in AG
set @distAGName = 'DistributionDBAg'								-- These details are
set @distListenerName = 'DistDbList'				-- not needed if 
set @distListenerPort = '6022'							-- distributor is not in AG

--sqlAcctName should be in this format {domainName}\{userName}
-- Example fareast\xyz

insert into @subscriberNodes values('SQL-VM-2', 'SQL20193', 0, 'corp\sqlsvc1')
insert into @subscriberNodes values('SQL-VM-1', 'SQL20193', 1, 'corp\sqlsvc1')

-- Need to add the publisher nodes here
insert into @publisherNodes values('SQL-VM-1', 'SQL20192')
insert into @publisherNodes values('SQL-VM-2', 'SQL20192')

-- Need to add the distributor nodes here
insert into @distributorNodes values('SQL-VM-1', 'SQL20191')
insert into @distributorNodes values('SQL-VM-2', 'SQL20191')

-- Need to add the listener IP details here
insert into @listenerIPDetails values('10.1.1.17', '255.255.255.0')
insert into @listenerIPDetails values('10.1.2.17', '255.255.255.0')

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

-- Calculate the number of nodes of subscriber and distributor
declare @numSubscriberNodes int
select @numSubscriberNodes = count(*) from  @subscriberNodes

declare @numDistributorNodes int
select @numDistributorNodes = count(*) from  @distributorNodes

-- declaring result which will contain the final script
declare @result nvarchar(max) = ''
declare @sqlServerInstName sysname

-- Fetching the primary node details
declare @primaryNodeName sysname
declare @primaryInsName sysname
select @primaryNodeName = nodeName, @primaryInsName = insName from @subscriberNodes where isPrimary = 1

-- Declaring variables which will be used by the script
declare @sqlAcctName sysname
declare @currNodeName sysname
declare @currInsName sysname
declare @connectionString sysname
declare @currSubnetMask sysname
declare @currIPAddress sysname

-- Check whether subscriber AG is in single subnet or in multiple subnets
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

if (@numSubscriberNodes > 1)
begin
-- Scripting creation of endpoint and xevents

declare sqlServerDetails_cursor cursor for
select nodeName, insName from @subscriberNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'IF NOT EXISTS(select * from sys.endpoints where name = ''Hadr_endpoint'')
BEGIN
	CREATE ENDPOINT [Hadr_endpoint]
	STATE = STARTED
	AS TCP (LISTENER_PORT = ' + @subEndpointPort +')
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

-- Confiure the remote login timeout to 60 seconds in the publisher nodes if subscriber AG has nodes in multiple subnet

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

-- Confiure the remote login timeout to 60 seconds in the distributor nodes if subscriber AG has nodes in multiple subnet

if (@isMultiSubnet = 1)
begin
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @distributorNodes
	open sqlServerDetails_cursor
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'sp_configure ''remote login timeout (s)'', 60
reconfigure' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	END
	ClOSE sqlServerDetails_cursor
	DEALLOCATE sqlServerDetails_cursor
end

-- Create AG

set @result = @result + dbo.fn_getConnectionString(@primaryNodeName, @primaryInsName) + 'IF NOT EXISTS(select * from sys.availability_groups where name = ''' + @subAGName + ''')
BEGIN
	CREATE AVAILABILITY GROUP ' +  @subAGName + ' FOR REPLICA ON ' + CHAR(13)
declare sqlServerDetails_cursor cursor for
select nodeName, insName from @subscriberNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	set @result = @result + CHAR(9) + '''' + dbo.fn_getSqlSeverInstanceName(@currNodeName, @currInsName) +  ''' WITH
	(
	ENDPOINT_URL = ''TCP://' + @currNodeName + '.' + @nodeDomainName + ':' + @subEndpointPort + ''',
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
'IF NOT EXISTS(select * from sys.availability_group_listeners where group_id = (select group_id from sys.availability_groups where name = ''' + @subAGName + '''))
BEGIN
	ALTER AVAILABILITY GROUP ' +  @subAGName + '
	ADD LISTENER ''' + @subListenerName + ''' (
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
	, PORT=' + @subListenerPort + ')
END' + CHAR(13) + 'go' + CHAR(13)
set @result = @result + 'print ''Listener of the AG has been created''' + CHAR(13) + CHAR(13)


-- Making all the replicas part of AG

declare sqlServerDetails_cursor cursor for
select nodeName, insName from @subscriberNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	If (NOT(@currNodeName = @primaryNodeName AND @currInsName = @primaryInsName))
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) + 
'IF NOT EXISTS(select * from sys.availability_groups where name = ''' + @subAGName + ''')
BEGIN
	ALTER AVAILABILITY GROUP ' + @subAGName + ' JOIN
	ALTER AVAILABILITY GROUP ' + @subAGName + ' GRANT CREATE ANY DATABASE
END' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
	END
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor
set @result = @result + 'print ''All the secondary replicas joined the AG''' + CHAR(13) + CHAR(13)

-- Add 32 and 64 bit alias in the publisher nodes if subscriber AG listener is running on a non-default port. Default port is 1433
if (@subListenerPort != '1433')
begin
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @publisherNodes
	open sqlServerDetails_cursor
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'exec dbo.xp_regwrite @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @subListenerName + ''', @type = ''REG_SZ'',
		@value = ''DBMSSOCN,' + @subListenerName + ',' + @subListenerPort + '''
exec dbo.xp_regwrite @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @subListenerName + ''', @type = ''REG_SZ'',
		@value = ''DBMSSOCN,' + @subListenerName + ',' + @subListenerPort + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	END
	ClOSE sqlServerDetails_cursor
	DEALLOCATE sqlServerDetails_cursor
end

-- Add 32 and 64 bit alias in the distributor nodes if subscriber AG listener is running on a non-default port. Default port is 1433
if (@subListenerPort != '1433')
begin
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @distributorNodes
	open sqlServerDetails_cursor
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'exec dbo.xp_regwrite @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @subListenerName + ''', @type = ''REG_SZ'',
		@value = ''DBMSSOCN,' + @subListenerName + ',' + @subListenerPort + '''
exec dbo.xp_regwrite @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @subListenerName + ''', @type = ''REG_SZ'',
		@value = ''DBMSSOCN,' + @subListenerName + ',' + @subListenerPort + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	END
	ClOSE sqlServerDetails_cursor
	DEALLOCATE sqlServerDetails_cursor
end

-- In case of pull subscription add 32 and 64 bit alias in the subscriber nodes if distributor AG listener is running on a non-default port
if (@subscriptionType = 'pull')
begin
	if (@numDistributorNodes > 1 AND @distListenerPort != '1433')
	begin
		declare sqlServerDetails_cursor cursor for
		select nodeName, insName from @subscriberNodes
		open sqlServerDetails_cursor
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
		WHILE @@FETCH_STATUS = 0
		BEGIN
			set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
	'exec dbo.xp_regwrite @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'',
			@value_name = ''' + @distListenerName + ''', @type = ''REG_SZ'',
			@value = ''DBMSSOCN,' + @distListenerName + ',' + @subListenerPort + '''
	exec dbo.xp_regwrite @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo'',
			@value_name = ''' + @distListenerName + ''', @type = ''REG_SZ'',
			@value = ''DBMSSOCN,' + @distListenerName + ',' + @subListenerPort + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
			fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
		END
		ClOSE sqlServerDetails_cursor
		DEALLOCATE sqlServerDetails_cursor
	end

-- Create listener of subscriber on the subscriber nodes
	if (@subListenerPort != '1433')
	begin
		declare sqlServerDetails_cursor cursor for
		select nodeName, insName from @subscriberNodes
		open sqlServerDetails_cursor
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
		WHILE @@FETCH_STATUS = 0
		BEGIN
			set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
	'exec dbo.xp_regwrite @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'',
			@value_name = ''' + @subListenerName + ''', @type = ''REG_SZ'',
			@value = ''DBMSSOCN,' + @subListenerName + ',' + @subListenerPort + '''
	exec dbo.xp_regwrite @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo'',
			@value_name = ''' + @subListenerName + ''', @type = ''REG_SZ'',
			@value = ''DBMSSOCN,' + @subListenerName + ',' + @subListenerPort + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
			fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
		END
		ClOSE sqlServerDetails_cursor
		DEALLOCATE sqlServerDetails_cursor
	end
end

-- Set the recovery of subscriber db to full if not already set
-- Backup the publisher db
-- Add the subscriber db to the AG
-- Configure log and full backups on subscriber db so as to truncate the logs (Needs to be done by end user)
set @result = @result + dbo.fn_getConnectionString(@primaryNodeName, @primaryInsName) +
'ALTER DATABASE ' + @subDatabase + ' SET RECOVERY FULL
BACKUP DATABASE ' + @subDatabase + ' TO  DISK = ''' + @backupSharePath + '\' + @subDatabase + '.bak''
ALTER AVAILABILITY GROUP ' + @subAGName + ' ADD DATABASE ' + @subDatabase + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
set @result = @result + 'print ''Added subscriber db to the availability group''' + CHAR(13) + CHAR(13)

end -- Ending the if(@numNodes > 1) check

-- Script creation for push subscription if subscriptionType is 'push'
if (@subscriptionType = 'push')
begin
	set @result = @result + dbo.fn_getConnectionString(@primaryPublisherNodeName, @primaryPublisherInsName) +
'use [' + @pubDatabase + ']
exec sp_addsubscription @publication = ''' + @publicationName + ''', @subscriber = ''' + @subListenerName + ''',
						@destination_db = ''' + @subDatabase + ''', @subscription_type = ''' + @subscriptionType + ''',
						@sync_type = N''automatic'', @article = N''all'', @update_mode = N''read only'', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = ''' + @publicationName + ''', @subscriber = ''' + @subListenerName + ''',
						@subscriber_db = ''' + @subDatabase + ''', @job_login = null, @job_password = null, @subscriber_security_mode = 1' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
set @result = @result + 'print ''Created a push subscription''' + CHAR(13) + CHAR(13)
end

else if (@subscriptionType = 'pull')
begin
	set @result = @result + dbo.fn_getConnectionString(@primaryPublisherNodeName, @primaryPublisherInsName) +
'use [' + @pubDatabase + ']
exec sp_addsubscription @publication = ''' + @publicationName + ''', @subscriber = ''' + @subListenerName + ''',
						@destination_db = ''' + @subDatabase + ''', @subscription_type = ''' + @subscriptionType + ''',
						@sync_type = N''automatic'', @article = N''all'', @update_mode = N''read only'', @subscriber_type = 0' + CHAR(13) + 'go' + CHAR(13)
	set @result = @result + dbo.fn_getConnectionString(@primaryNodeName, @primaryInsName) +
'use [' + @subDatabase + ']
exec sp_addpullsubscription @publisher = ''' + dbo.fn_getSqlSeverInstanceName(@originalPublisherNodeName, @originalPublisherInsName) + ''',
						@publisher_db = ''' + @pubDatabase + ''', @publication = ''' + @publicationName + ''', @subscription_type = N''pull''
exec sp_addpullsubscription_agent @publisher = ''' + dbo.fn_getSqlSeverInstanceName(@originalPublisherNodeName, @originalPublisherInsName) + ''',
						@subscriber = ''' + @subListenerName + ''', @publisher_db = ''' + @pubDatabase + ''', @distributor = ''' + @distListenerName + ''',
						@publication = ''' + @publicationName + ''', @frequency_type = 64, @job_login = null, @job_password = null, @subscriber_security_mode = 1' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
end

-- Scripting creation of linked servers of subscriber AG at all publisher nodes if not created

declare sqlServerDetails_cursor cursor for
select nodeName, insName from @publisherNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) + 
'IF NOT EXISTS (select * from sys.sysservers where srvname = ''' + @subListenerName + ''')
BEGIN
	exec dbo.sp_addlinkedserver @server = ''' + @subListenerName + ''', @srvproduct=N''SQL Server''
	exec dbo.sp_addlinkedsrvlogin @rmtsrvname= ''' + @subListenerName + ''', @useself=N''True'',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL
END' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor
set @result = @result + 'print ''Created linked servers of subscriber AG at all publisher nodes''' + CHAR(13) + CHAR(13)

-- Scripting creation of linked servers of subscriber AG at all distributor nodes if not created

declare sqlServerDetails_cursor cursor for
select nodeName, insName from @distributorNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
	set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) + 
'IF NOT EXISTS (select * from sys.sysservers where srvname = ''' + @subListenerName + ''')
BEGIN
	exec dbo.sp_addlinkedserver @server = ''' + @subListenerName + ''', @srvproduct=N''SQL Server''
	exec dbo.sp_addlinkedsrvlogin @rmtsrvname= ''' + @subListenerName + ''', @useself=N''True'',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL
END' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor
set @result = @result + 'print ''Created linked servers of subscriber AG at all distributor nodes''' + CHAR(13) + CHAR(13)

-- Ending of setup script
set @result = @result + '-- Ending of setup script' + CHAR(13) + CHAR(13)

cleanup:
if (@generateScript = 'setup')
goto printResult

--Starting of cleanup script
set @result = @result + '-- Starting of cleanup script' + CHAR(13) + CHAR(13)

-- Scripting condition to exit in case of errors
set @result = @result + ':On error exit' + CHAR(13) + CHAR(13)

--Drop the push/pull subscription if exists
set @result = @result + dbo.fn_getConnectionString(@primaryPublisherNodeName, @primaryPublisherInsName) + 
'use [' + @pubDatabase + ']
declare @found int
exec sp_helpsubscription @publication =  ''' + @publicationName + ''', @subscriber = ''' + @subListenerName + ''',
						 @destination_db = ''' + @subDatabase + ''', @found= @found OUTPUT
if (@found = 1)
begin
	exec sp_dropsubscription @publication = ''' + @publicationName + ''', @article =  ''all'',
							 @subscriber=  ''' + @subListenerName + ''',  @destination_db = ''' + @subDatabase + '''
end' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)

if (@subscriptionType = 'pull')
begin
	set @result = @result + dbo.fn_getConnectionString(@primaryNodeName, @primaryInsName) +
'use [' + @subDatabase + ']
if object_id(''MSreplication_subscriptions'') is not null
begin
	if exists(select * from MSreplication_subscriptions where publisher = ''' + dbo.fn_getSqlSeverInstanceName(@originalPublisherNodeName, @originalPublisherInsName) + '''
				AND publisher_db = ''' + @pubDatabase + ''' AND publication = ''' + @publicationName + '''
				AND subscription_type = 1)
	begin
		exec sp_droppullsubscription @publisher = ''' + dbo.fn_getSqlSeverInstanceName(@originalPublisherNodeName, @originalPublisherInsName) + ''',
				@publisher_db = ''' + @pubDatabase + ''',
				@publication = ''' + @publicationName + ''' 
	end		
end' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
end

if (@numSubscriberNodes > 1)
begin
-- Drop the availability group
set @result = @result + dbo.fn_getConnectionString(@primaryNodeName, @primaryInsName) + 'IF EXISTS(select * from sys.availability_groups where name = ''' + @subAGName + ''')
	DROP AVAILABILITY GROUP ' + @subAGName + CHAR(13) + 'go' + CHAR(13) + CHAR(13)

-- Restore all the primary and subscriber databases
declare sqlServerDetails_cursor cursor for
select nodeName, insName from @subscriberNodes
open sqlServerDetails_cursor
fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
WHILE @@FETCH_STATUS = 0
BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) + 
'IF EXISTS(select * from sys.databases where name = ''' + @subDatabase + ''' and state_desc = ''RESTORING'')
BEGIN
	RESTORE DATABASE ' + @subDatabase + ' WITH RECOVERY
END' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
END
ClOSE sqlServerDetails_cursor
DEALLOCATE sqlServerDetails_cursor

end -- Ending the if(@numNodes > 1) check

-- Drop the alias on the publisher nodes if created
if (@subListenerPort != '1433')
begin
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @publisherNodes
	open sqlServerDetails_cursor
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'exec dbo.xp_regdeletevalue @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @subListenerName + '''
exec dbo.xp_regdeletevalue @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @subListenerName + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	END
	ClOSE sqlServerDetails_cursor
	DEALLOCATE sqlServerDetails_cursor
end

-- Drop the alias on the distributor nodes if created
if (@subListenerPort != '1433')
begin
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @distributorNodes
	open sqlServerDetails_cursor
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'exec dbo.xp_regdeletevalue @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @subListenerName + '''
exec dbo.xp_regdeletevalue @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @subListenerName + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	END
	ClOSE sqlServerDetails_cursor
	DEALLOCATE sqlServerDetails_cursor
end

if (@subscriptionType = 'pull' AND @distListenerPort != '1433')
begin
-- Drop the alias of distributor listener on the subscriber nodes if created
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @subscriberNodes
	open sqlServerDetails_cursor
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		if not exists (select * from @publisherNodes where nodeName = @currNodeName)
		begin
			if not exists (select * from @distributorNodes where nodeName = @currNodeName)
			begin
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'exec dbo.xp_regdeletevalue @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @distListenerName + '''
exec dbo.xp_regdeletevalue @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @distListenerName + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
			end
		end
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	END
	ClOSE sqlServerDetails_cursor
	DEALLOCATE sqlServerDetails_cursor

-- Drop the alias of subscriber listener on the subscriber nodes if created
	declare sqlServerDetails_cursor cursor for
	select nodeName, insName from @subscriberNodes
	open sqlServerDetails_cursor
	fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @result = @result + dbo.fn_getConnectionString(@currNodeName, @currInsName) +
'exec dbo.xp_regdeletevalue @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @subListenerName + '''
exec dbo.xp_regdeletevalue @rootkey = ''HKEY_LOCAL_MACHINE'', @key = ''SOFTWARE\WOW6432Node\Microsoft\MSSQLServer\Client\ConnectTo'',
		@value_name = ''' + @subListenerName + '''' + CHAR(13) + 'go' + CHAR(13) + CHAR(13)
		fetch next from sqlServerDetails_cursor into @currNodeName, @currInsName
	END
	ClOSE sqlServerDetails_cursor
	DEALLOCATE sqlServerDetails_cursor
end

set @result = @result + 'print ''''' + CHAR(13)
set @result = @result + 'print ''NOTE : SUBSCRIBER DATABASES ARE PRESENT ON BOTH PRIMARY AND SECONDARY REPLICAS. YOU CAN DELETE THEM IF NOT NEEDED''' + CHAR(13)
set @result = @result + 'print ''NOTE : THE LINKED SERVERS FOR THE SUBSCRIBER/ SUBSCRIBER LISTENER ON PUBLISHER AND DISTRIBUTOR NODES ARE NOT DROPPED''' + CHAR(13)
set @result = @result + 'print ''NOTE : IF THE LINKED SERVERS ARE NOT REQUIRED KNIDLY DROP THEM FROM PUBLISHER AND DISTRIBUTOR NODES''' + CHAR(13) + CHAR(13)

-- Ending of cleanup script
set @result = @result + '-- Ending of cleanup script' + CHAR(13)

printResult:
-- Drop the created functions
drop function fn_getConnectionString
drop function fn_getSqlSeverInstanceName

-- Prints the final script
exec sp_printResult @result

/* ************************************************************************
   ************************************************************************ */

