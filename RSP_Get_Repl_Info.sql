/* dbo.RSP_Get_Repl_Info Version 0.3

This Procedure is something we use in support that can be executed quickly to get basic information about a replication environment.  It should be executed on a distributor and takes the name of the Distribution database as an input parameter.  It can be created in any database.  
Results should be viewed in TEXT or output directly TO FILE.  Note that all of the select statements include a NOLOCK hint.

EXAMPLE:
exec dbo.RSP_Get_Repl_Info 'distribution'

You'll want to take a look at the output for yourself.  Much of the data returned is just the names of publications, subscriptions, and some agent history.  Some more advanced data returned includes counts and queries from merge publication dbs (if the distributor is also a merge publisher), as well as counts from transactional meta data tables.  The final section includes some command text of commands in the distribution database.

*/

CREATE PROCEDURE [dbo].[RSP_Get_Repl_Info]
@DistributionDB nvarchar (50) --name of the distributiondb to be queried is required in case there are multiple distribution dbs
AS

/* If you don't want to create a procedure, uncomment the following variable declaration and set statements and then run from BEGIN below as an ad-hoc query, being sure to use the correct distribution database name */

BEGIN

Set Nocount On

--declare @DistributionDB nvarchar (50)

--set @DistributionDB = 'distribution'

--DECLARE VARIABLES

declare @SN varchar (100)
declare @VN varchar (4000)
declare @srvnetname varchar (100)
declare @pubdb nvarchar (100)
declare @pub_srvname nvarchar (100)
declare @contents_size int
declare @tombstone_size int
declare @genhistory_size int
declare @partition_groups_size int
declare @current_partition_mappings_size int
declare @past_partition_mappings_size int
declare @xactno varbinary(16)
declare @count int

--GET DISTRIBUTOR NAME
set @SN = @@servername
set @VN = @@version
select @srvnetname = (select srvnetname from master..sysservers with (nolock) where dist = 1)
If @srvnetname is null set @srvnetname = 'null'
If
@srvnetname = @SN
Print 'This SQL server, ' + @SN + 
', appears to be a distributor. 
The version of ' + @SN + ' is ' + @VN + '
'
Else
Print 'This SQL server, ' + @SN + ', does not appear to be a distributor. Errors may occur.
The distributor for ' + @SN + ' is ' + @srvnetname + '
'
--CREATE SYNONYMS FOR THE DISTRIBUTION TABLES WE WILL QUERY
---This lets us avoid creating dynamic sql statements for different distribution db names
---Test if synonyms exist from previous executions of this SP and drop them if they do
if OBJECT_ID ('SYN_MSsubscriptions_MSFTUniqueSYN') is not null drop synonym SYN_MSsubscriptions_MSFTUniqueSYN
if OBJECT_ID ('SYN_MSpublications_MSFTUniqueSYN') is not null drop synonym SYN_MSpublications_MSFTUniqueSYN
if OBJECT_ID ('SYN_MSpublisher_databases_MSFTUniqueSYN') is not null drop synonym SYN_MSpublisher_databases_MSFTUniqueSYN
if OBJECT_ID ('SYN_MSarticles_MSFTUniqueSYN') is not null drop synonym SYN_MSarticles_MSFTUniqueSYN
if OBJECT_ID ('SYN_MSmerge_agents_MSFTUniqueSYN') is not null drop synonym SYN_MSmerge_agents_MSFTUniqueSYN
if OBJECT_ID ('SYN_MSmerge_subscriptions_MSFTUniqueSYN') is not null drop synonym SYN_MSmerge_subscriptions_MSFTUniqueSYN
if OBJECT_ID ('SYN_MSmerge_history_MSFTUniqueSYN') is not null drop synonym SYN_MSmerge_history_MSFTUniqueSYN
if OBJECT_ID ('SYN_MSdistribution_agents_MSFTUniqueSYN') is not null drop synonym SYN_MSdistribution_agents_MSFTUniqueSYN
if OBJECT_ID ('SYN_MSdistribution_history_MSFTUniqueSYN') is not null drop synonym SYN_MSdistribution_history_MSFTUniqueSYN
if OBJECT_ID ('SYN_MSrepl_errors_MSFTUniqueSYN') is not null drop synonym SYN_MSrepl_errors_MSFTUniqueSYN
if OBJECT_ID ('SYN_MSrepl_transactions_MSFTUniqueSYN') is not null drop synonym SYN_MSrepl_transactions_MSFTUniqueSYN
if OBJECT_ID ('SYN_MSrepl_commands_MSFTUniqueSYN') is not null drop synonym SYN_MSrepl_commands_MSFTUniqueSYN
---Create synonyms from the input parameter
exec('
create synonym SYN_MSsubscriptions_MSFTUniqueSYN for [' + @DistributionDB + ']..MSsubscriptions
create synonym SYN_MSpublications_MSFTUniqueSYN for [' + @DistributionDB + ']..MSpublications
create synonym SYN_MSpublisher_databases_MSFTUniqueSYN for [' + @DistributionDB + ']..MSpublisher_databases
create synonym SYN_MSarticles_MSFTUniqueSYN for [' + @DistributionDB + ']..MSarticles
create synonym SYN_MSmerge_agents_MSFTUniqueSYN for [' + @DistributionDB + ']..MSmerge_agents
create synonym SYN_MSmerge_subscriptions_MSFTUniqueSYN for [' + @DistributionDB + ']..MSmerge_subscriptions
create synonym SYN_MSmerge_history_MSFTUniqueSYN for [' + @DistributionDB + ']..MSmerge_history
create synonym SYN_MSdistribution_agents_MSFTUniqueSYN for [' + @DistributionDB + ']..MSdistribution_agents
create synonym SYN_MSdistribution_history_MSFTUniqueSYN for [' + @DistributionDB + ']..MSdistribution_history
create synonym SYN_MSrepl_errors_MSFTUniqueSYN for [' + @DistributionDB + ']..MSrepl_errors
create synonym SYN_MSrepl_transactions_MSFTUniqueSYN for [' + @DistributionDB + ']..MSrepl_transactions
create synonym SYN_MSrepl_commands_MSFTUniqueSYN for [' + @DistributionDB + ']..MSrepl_commands
')
--CREATE TEMP TABLES WE WILL NEED
If Object_Id('tempdb..#pubtype') Is Not Null 
Drop Table #pubtype
Create Table #pubtype (TypeId smallint, pubtype char (40))
Insert Into #pubtype Values (0,'Transactional')
Insert Into #pubtype Values (1,'Snapshot')
Insert Into #pubtype Values (2,'Merge')
--select * from #pubtype
If Object_Id('tempdb..#subtype') Is Not Null 
Drop Table #subtype
Create Table #subtype (TypeId smallint, subtype char (40))
Insert Into #subtype Values (0,'Push')
Insert Into #subtype Values (1,'Pull')
Insert Into #subtype Values (2,'Anonymous')
--select * from #subtype
If Object_Id('tempdb..#substatus') Is Not Null 
Drop Table #substatus
Create Table #substatus (TypeId smallint, substatus char (40))
Insert Into #substatus Values (0,'Inactive')
Insert Into #substatus Values (1,'Subscribed')
Insert Into #substatus Values (2,'Active')
--select * from #substatus
If Object_Id('tempdb..#sub_idstatus') Is Not Null 
Drop Table #sub_idstatus
Create Table #sub_idstatus (agent_id smallint, subscriber_id smallint, sub_idstatus smallint)
Insert #sub_idstatus
Select Distinct agent_id, subscriber_id, status from SYN_MSsubscriptions_MSFTUniqueSYN with (nolock)
--select * from #sub_idstatus
If Object_Id('tempdb..#merge_sub_idtype') Is Not Null 
Drop Table #merge_sub_idtype
Create Table #merge_sub_idtype (agent_id smallint, subscriber nvarchar (40), subscription_type smallint)
Insert #merge_sub_idtype
select distinct ma.id, mu.subscriber, mu.subscription_type
from SYN_MSmerge_agents_MSFTUniqueSYN as ma with (nolock)
join SYN_MSmerge_subscriptions_MSFTUniqueSYN as mu with (nolock)
on (ma.subscriber_name = mu.subscriber)
--select * from #merge_sub_idtype
If Object_Id('tempdb..#genstatus') Is Not Null 
Drop Table #genstatus
Create Table #genstatus (TypeId smallint, genstatus char (25))
Insert Into #genstatus Values (0,'Open')
Insert Into #genstatus Values (1,'Closed')
Insert Into #genstatus Values (2,'Closed From Sub')
--select * from #genstatus
print '
----------
THE FOLLOWING SECTION GATHERS GENERAL REPLICATION INFO INCLUDING PUBLICATIONS, SUBSCRIPTIONS, AND SOME HISTORY DETAILS
----------
'
--GET PUBLICATION INFO FOR THIS DISTRIBUTOR
Print '
PUBLICATION INFO FOR THIS DISTRIBUTOR
---'
select left (dp.publication, 40) as publication, left (ms.srvname, 40) as publisher, left (dp.publisher_db, 40) as publisher_db, pt.pubtype as publication_type, md.publisher_type as publisher_type
from SYN_MSpublications_MSFTUniqueSYN dp with (nolock)
join master..sysservers ms with (nolock)
on (dp.publisher_id = ms.srvid)
join #pubtype pt with (nolock)
on (dp.publication_type = pt.TypeId)
join msdb.dbo.MSdistpublishers md with (nolock)
on (ms.srvname = md.name)
order by publication_id
--GET TRANSACTIONAL SUBSCRIPTION INFO
Print '
TRANSACTIONAL SUBSCRIPTION INFO FOR THIS DISTRIBUTOR
---'
select left (da.publication, 40) as publication, left (ms.srvname, 40) as subscriber, left (da.subscriber_db, 40) as subscriber_db, pt.pubtype as publication_type, st.subtype as subscription_type, ss.substatus as subscription_status, da.name as agent_name 
from SYN_MSdistribution_agents_MSFTUniqueSYN da with (nolock)
join master..sysservers ms with (nolock)
on (da.subscriber_id = ms.srvid)
join SYN_MSpublications_MSFTUniqueSYN dp with (nolock)
on (da.publication = dp.publication)
join #pubtype pt with (nolock)
on (dp.publication_type = pt.TypeId)
join #subtype st with (nolock)
on (da.subscription_type = st.TypeId)
join #sub_idstatus si with (nolock)
on (da.subscriber_id = si.subscriber_id)
join #substatus ss with (nolock)
on (si.sub_idstatus = ss.TypeId)
where si.agent_id = da.id
order by ms.srvname
--GET SOME RECENT DISTRIBUTION AGENT HISTORY
PRINT '
RECENT DISTRIBUTION AGENT HISTORY
---'
select top 50 left (da.publication, 25) as publication, left (ms.srvname, 25) as subscriber, left (da.subscriber_db, 25) as subscriber_db, left (dh.comments, 300) as comments, dh.time, da.name as agent_name
from SYN_MSdistribution_history_MSFTUniqueSYN dh with (nolock)
join SYN_MSdistribution_agents_MSFTUniqueSYN da with (nolock)
on (dh.agent_id = da.id)
join master..sysservers ms with (nolock)
on (da.subscriber_id = ms.srvid)
order by time desc
--GET MERGE SUBSCRIPTION INFO
---You may see duplicate rows in the list of subscriptions if a subscriber has both push and pull subscriptions
Print '
MERGE SUBSCRIPTION INFO FOR THIS DISTRIBUTOR
---'
select left (ma.publication, 40) as publication, left (ma.subscriber_name, 40) as subscriber, left (ma.subscriber_db, 40) as subscriber_db, pt.pubtype as publication_type, st.subtype as subscription_type, ma.name as agent_name
from SYN_MSmerge_agents_MSFTUniqueSYN ma with (nolock)
join SYN_MSpublications_MSFTUniqueSYN dp with (nolock)
on (ma.publication = dp.publication)
join #merge_sub_idtype mst with (nolock)
on (ma.id = mst.agent_id)
join #subtype st with (nolock)
on (mst.subscription_type = st.TypeId)
join #pubtype pt with (nolock)
on (dp.publication_type = pt.TypeId)
order by ma.subscriber_name
--GET SOME RECENT MERGE AGENT HISTORY
PRINT '
RECENT MERGE AGENT HISTORY
---'
select top 50 left (ma.publication, 25) as publication, left (ma.subscriber_name, 25) as subscriber, left (ma.subscriber_db, 25) as subscriber_db, left (mh.comments, 300) as comments, mh.time, ma.name as agent_name
from SYN_MSmerge_history_MSFTUniqueSYN mh with (nolock)
join SYN_MSmerge_agents_MSFTUniqueSYN ma with (nolock)
on (mh.agent_id = ma.id)
order by time desc
--GET SOME RECENT REPLICATION ERROR INFORMATION
PRINT '
RECENT REPLICATION ERROR INFO
---'
select top 50 time, error_text, left (error_code, 25) as error_code, left (source_name, 25) as source_name
from SYN_MSrepl_errors_MSFTUniqueSYN with (nolock)
order by time desc
print '
---------- 
THE FOLLOWING SECTION INCLUDES METADATA INFO FOR MERGE PUBLICATION DATABASES
IF THIS SERVER IS NOT A MERGE PUBLISHER, ERRORS MAY OCCUR BUT ARE SAFE TO IGNORE
----------
'
--THIS SECTION HAS INFORMATION SPECIFIC TO THE MERGE PUBLISHER DBs
--CURSOR THROUGH THE MERGE PUBLISHER DBs ON THIS SERVER
declare PubDbs Cursor for
select distinct dp.publisher_db , ms.srvname
from SYN_MSpublications_MSFTUniqueSYN dp with (nolock)
join master..sysservers ms with (nolock)
on (dp.publisher_id = ms.srvid)
where publication_type = 2 and ms.srvname = @@servername
open PubDbs
fetch next from PubDbs
into @pubdb, @pub_srvname
While @@fetch_status = 0
BEGIN
--HANDLE DATABASE CONTEXT BY USING SYNONYMS
---Test if synonyms exist to avoid errors on the first pass of the cursor
---Drop synonyms on each exec of the cursor after changing to the next publication database
if OBJECT_ID ('SYN_tombstone_MSFTUniqueSYN') is not null drop synonym SYN_tombstone_MSFTUniqueSYN
if OBJECT_ID ('SYN_contents_MSFTUniqueSYN') is not null drop synonym SYN_contents_MSFTUniqueSYN
if OBJECT_ID ('SYN_genhistory_MSFTUniqueSYN') is not null drop synonym SYN_genhistory_MSFTUniqueSYN
if OBJECT_ID ('SYN_partition_groups_MSFTUniqueSYN') is not null drop synonym SYN_partition_groups_MSFTUniqueSYN
if OBJECT_ID ('SYN_current_partition_mappings_MSFTUniqueSYN') is not null drop synonym SYN_current_partition_mappings_MSFTUniqueSYN
if OBJECT_ID ('SYN_past_partition_mappings_MSFTUniqueSYN') is not null drop synonym SYN_past_partition_mappings_MSFTUniqueSYN
if OBJECT_ID ('SYN_sysmergearticles_MSFTUniqueSYN') is not null drop synonym SYN_sysmergearticles_MSFTUniqueSYN
if OBJECT_ID ('SYN_sysmergepublications_MSFTUniqueSYN') is not null drop synonym SYN_sysmergepublications_MSFTUniqueSYN
exec('
create synonym SYN_contents_MSFTUniqueSYN for [' + @pubdb + ']..msmerge_contents
create synonym SYN_tombstone_MSFTUniqueSYN for [' + @pubdb + ']..msmerge_tombstone
create synonym SYN_genhistory_MSFTUniqueSYN for [' + @pubdb + ']..msmerge_genhistory
create synonym SYN_partition_groups_MSFTUniqueSYN for [' + @pubdb + ']..msmerge_partition_groups
create synonym SYN_current_partition_mappings_MSFTUniqueSYN for [' + @pubdb + ']..msmerge_current_partition_mappings
create synonym SYN_past_partition_mappings_MSFTUniqueSYN for [' + @pubdb + ']..msmerge_past_partition_mappings
create synonym SYN_sysmergearticles_MSFTUniqueSYN for [' + @pubdb + ']..sysmergearticles
create synonym SYN_sysmergepublications_MSFTUniqueSYN for [' + @pubdb + ']..sysmergepublications
')

print '
---
METADATA INFO FOR MERGE PUBLICATION DATABASE "' + @pubdb + '"
---'
--GET THE SIZE OF SOME METADATA TABLES
print '
METADATA TABLE SIZES IN ROWS
---'
select @contents_size = count(*) from SYN_contents_MSFTUniqueSYN with (nolock)
select @tombstone_size = count(*) from SYN_tombstone_MSFTUniqueSYN with (nolock)
select @genhistory_size = count(*) from SYN_genhistory_MSFTUniqueSYN with (nolock)
select @partition_groups_size = count(*) from SYN_partition_groups_MSFTUniqueSYN with (nolock)
select @current_partition_mappings_size = count(*) from SYN_current_partition_mappings_MSFTUniqueSYN with (nolock)
select @past_partition_mappings_size = count(*) from SYN_past_partition_mappings_MSFTUniqueSYN with (nolock)

select @contents_size as 'MSmerge_contents',
@tombstone_size as 'MSmerge_tombstone',
@genhistory_size as 'MSmerge_genhistory',
@partition_groups_size as 'MSmerge_partition_groups',
@current_partition_mappings_size as 'MSmerge_current_partition_mappings',
@past_partition_mappings_size as 'MSmerge_past_partition_mappings'
--TOP 25 COUNT OF GENERATIONS BY DAY
Print '
DAYS WITH THE HIGHEST NUMBER OF GENERATIONS
---'
select top 25 left (gh.coldate, 11) as day, count (*) as #_of_generations
from SYN_sysmergearticles_MSFTUniqueSYN pa with (nolock)
join SYN_genhistory_MSFTUniqueSYN gh with (nolock)
on (pa.nickname = gh.art_nick)
join SYN_sysmergepublications_MSFTUniqueSYN pp with (nolock)
on (pa.pubid = pp.pubid)
group by left (gh.coldate, 11)
order by #_of_generations desc
--TOP 25 MOST RECENT GENERATIONS WITH PUBLICATION, ARTICLE, AND # OF CHANGES
Print '
MOST RECENT GENERATIONS
---'
select top 25 left (pp.name, 25) as publication_name, left(pa.name, 25) as article_name, gh.coldate as generation_date, gh.changecount as #_of_changes, gs.genstatus, gh.generation, left (pp.publisher, 25) as publisher, left (pp.publisher_db, 25) as publisher_db 
from SYN_sysmergearticles_MSFTUniqueSYN pa with (nolock)
join SYN_genhistory_MSFTUniqueSYN gh with (nolock)
on (pa.nickname = gh.art_nick)
join SYN_sysmergepublications_MSFTUniqueSYN pp with (nolock)
on (pa.pubid = pp.pubid)
join #genstatus gs 
on (gh.genstatus = gs.TypeId)
order by gh.coldate desc

fetch next from PubDbs
into @pubdb, @pub_srvname
END
Close PubDbs
Deallocate PubDbs
--DROP THE PUBLICATION DATABASE SYNONYMS
if OBJECT_ID ('SYN_tombstone_MSFTUniqueSYN') is not null drop synonym SYN_tombstone_MSFTUniqueSYN
if OBJECT_ID ('SYN_contents_MSFTUniqueSYN') is not null drop synonym SYN_contents_MSFTUniqueSYN
if OBJECT_ID ('SYN_genhistory_MSFTUniqueSYN') is not null drop synonym SYN_genhistory_MSFTUniqueSYN
if OBJECT_ID ('SYN_partition_groups_MSFTUniqueSYN') is not null drop synonym SYN_partition_groups_MSFTUniqueSYN
if OBJECT_ID ('SYN_current_partition_mappings_MSFTUniqueSYN') is not null drop synonym SYN_current_partition_mappings_MSFTUniqueSYN
if OBJECT_ID ('SYN_past_partition_mappings_MSFTUniqueSYN') is not null drop synonym SYN_past_partition_mappings_MSFTUniqueSYN
if OBJECT_ID ('SYN_sysmergearticles_MSFTUniqueSYN') is not null drop synonym SYN_sysmergearticles_MSFTUniqueSYN
if OBJECT_ID ('SYN_sysmergepublications_MSFTUniqueSYN') is not null drop synonym SYN_sysmergepublications_MSFTUniqueSYN

PRINT '
---------- 
THE FOLLOWING SECTION INCLUDES INFO ABOUT TRANSACTIONAL REPLICATION METADATA FROM THE DISTRIBUTION DATABASE
----------
'
--TOP 25 COUNT OF TRANSACTIONS BY DAY
Print '
DAYS WITH THE HIGHEST NUMBER OF TRANSACTIONS
---' 
select top 25 left (mt.entry_time, 11) as day, count(*) as #_of_transactions
from SYN_MSrepl_transactions_MSFTUniqueSYN mt with (nolock)
join SYN_MSpublisher_databases_MSFTUniqueSYN dd with (nolock)
on (mt.publisher_database_id = dd.id) 
group by left (mt.entry_time, 11)
order by #_of_transactions desc 
--TOP 25 COUNT OF COMMANDS BY TRANSACT NUMBER
PRINT '
TRANSACTIONS WITH THE HIGHEST NUMBER OF COMMANDS
---'
select top 25 mc.xact_seqno, left (dd.publisher_db, 45) as publisher_db, count(*) as #_of_commands
from SYN_MSrepl_commands_MSFTUniqueSYN mc with (nolock)
join SYN_MSpublisher_databases_MSFTUniqueSYN dd with (nolock)
on (mc.publisher_database_id = dd.id)
group by mc.xact_seqno, dd.publisher_db 
order by #_of_commands desc
--SOME COMMANDS FROM THE 2 TRANSACTIONS WITH THE HIGHEST COMMAND COUNT
PRINT '
----------
THE FOLLOWING SECTION RETURNS INFO ABOUT THE 2 TRANSACTIONS WITH THE HIGHEST COMMAND COUNT 
NOT ALL COMMANDS WILL ''CAST'' CORRECTLY
USE SP_BROWSEREPLECMDS IF THE COMMAND COLUMN RETURNS GARBAGE
----------
'
declare xact_count cursor for
select top 2 xact_seqno, count(*) as #_of_commands
from SYN_MSrepl_commands_MSFTUniqueSYN with (nolock)
group by xact_seqno 
order by #_of_commands desc
open xact_count
fetch next from xact_count
into @xactno, @count
While @@fetch_status = 0
BEGIN
print '
---
COMMAND INFO FOR NEXT TRANSACTION 
---'
select top 25 mc.command_id, left (dr.article, 45) as article, left (ms.srvname, 45) as publisher, left (dd.publisher_db, 45) as publisher_db, cast(mc.command as nvarchar(1000)) as command, mc.xact_seqno
from SYN_MSrepl_commands_MSFTUniqueSYN mc with (nolock)
join SYN_MSpublisher_databases_MSFTUniqueSYN dd with (nolock)
on (mc.publisher_database_id = dd.id)
join master..sysservers ms with (nolock)
on (dd.publisher_id = ms.srvid)
join SYN_MSarticles_MSFTUniqueSYN dr with (nolock)
on (mc.article_id = dr.article_id)
where dd.publisher_id = dr.publisher_id 
AND mc.xact_seqno = @xactno
order by command_id
fetch next from xact_count
into @xactno, @count
END
Close xact_count
Deallocate xact_count
--DROP THE TEMP TABLES
Drop Table #pubtype
Drop Table #subtype
Drop Table #substatus
Drop Table #sub_idstatus
Drop Table #merge_sub_idtype
Drop Table #genstatus
--DROP THE DISTRIBUTION DATABASE SYNONYMS
Drop Synonym SYN_MSsubscriptions_MSFTUniqueSYN
Drop Synonym SYN_MSpublications_MSFTUniqueSYN
Drop Synonym SYN_MSpublisher_databases_MSFTUniqueSYN
Drop Synonym SYN_MSarticles_MSFTUniqueSYN
Drop Synonym SYN_MSmerge_agents_MSFTUniqueSYN
Drop Synonym SYN_MSmerge_subscriptions_MSFTUniqueSYN
Drop Synonym SYN_MSmerge_history_MSFTUniqueSYN
Drop Synonym SYN_MSdistribution_agents_MSFTUniqueSYN
Drop Synonym SYN_MSdistribution_history_MSFTUniqueSYN
Drop Synonym SYN_MSrepl_errors_MSFTUniqueSYN
Drop Synonym SYN_MSrepl_transactions_MSFTUniqueSYN
Drop Synonym SYN_MSrepl_commands_MSFTUniqueSYN
Set Nocount Off
END

