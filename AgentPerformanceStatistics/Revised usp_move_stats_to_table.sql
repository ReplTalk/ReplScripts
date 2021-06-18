--Script to load MSlogreader_history and MSdistribution_history run statistics
-- from XML data into table which can be easily queried.
--
--Script creates MS_replstats database containing the results. This database
-- can be backed-up, moved, restored as needed.
--
-- Written by: Charles (Curt) Mathews
-- Modified by: Chris Skorlinski
--
--In this script, the stored procedure below is executed to
-- move Replication Agent statistics stored in XML format
-- from Replication history tables into a table format
-- in a MS_replstats database created by this script.
--
-- note: Scripts must not be run in a transaction
--
------------------------------------------------------------
-- 1) Return list of DistributionDB(s)
-- Run command below on the published database
-- update script with "distribution.dbo." as needed
-- with correct distribution database name
--
------------------------------------------------------------
sp_helpdistributor
GO
------------------------------------------------------------
-- Step 2) create MS_replstats database and table to hold stats
--
-- Table MS_perf_stats contains both logreader and distrib perf stats that can be
-- queried independently by using WHERE TYPE='Distrib' or WHERE TYPE='LogRead'
------------------------------------------------------------
SET IMPLICIT_TRANSACTIONS OFF
IF @@TRANCOUNT > 0 ROLLBACK TRAN
GO
-- Options that are saved with object definition
SET QUOTED_IDENTIFIER ON -- Required to call methods on XML type
SET ANSI_NULLS ON -- All queries use IS NULL check
GO
--STOP the create database if [MS_replstats] already exists
--Manually drop as needed to ensure this table can be deleted.
-- DROP DATABASE [MS_replstats]
GO
CREATE DATABASE MS_replstats
GO
USE MS_replstats
GO
IF not EXISTS (SELECT * FROM sys.schemas WHERE NAME = 'MS_ReplStats')
EXEC('CREATE SCHEMA MS_ReplStats')
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[MS_ReplStats].[MS_perf_stats]') AND type in (N'U'))
DROP TABLE [MS_ReplStats].[MS_perf_stats]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [MS_ReplStats].[MS_perf_stats](
[state] [int] NULL,
[work] [int] NULL,
[idle] [int] NULL,
[fetch] [int] NULL,
[fetch_wait] [int] NULL,
[cmds] [int] NULL,
[callstogetreplcmds] [int] NULL,
[write] [int] NULL,
[write_wait] [int] NULL,
[sincelaststats_elapsed_time] [int] NULL,
[sincelaststats_work] [int] NULL,
[sincelaststats_cmds] [int] NULL,
[sincelaststats_cmdspersec] [numeric](18, 0) NULL,
[sincelaststats_fetch] [int] NULL,
[sincelaststats_fetch_wait] [int] NULL,
[sincelaststats_write] [int] NULL,
[sincelaststats_write_wait] [int] NULL,
[time] [datetime] NULL,
[agent_id] int NULL,
[type] [nvarchar] (25) NULL
) ON [PRIMARY]
GO
------------------------------------------------------------
-- Step 3) Create procedure usp_move_stats_to_table which opens a
-- cursor on table MSlogreader_history and MSdistribution_history,
-- then, for each row, calls procedure move_stats_to_tab to extract
-- the xml stats data into table MS_perf_stats.
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[MS_ReplStats].[usp_MSINTERNAL_move_stats_to_table]') AND type in (N'P', N'PC'))
DROP PROCEDURE [MS_ReplStats].[usp_MSINTERNAL_move_stats_to_table]
GO
--procedure to convert XML data
CREATE PROCEDURE [MS_ReplStats].[usp_MSINTERNAL_move_stats_to_table] (@xpath nvarchar(500), @time datetime, @agent_id int, @type nvarchar(25))
AS
DECLARE @xmldoc int
EXEC sp_xml_preparedocument @xmldoc OUTPUT, @xpath
DECLARE @getstate varchar(1)
SELECT @getstate=SUBSTRING ( @xpath, 15 , 1)
if @getstate='1'
INSERT INTO [MS_ReplStats].[MS_perf_stats]
([state], work, idle, [fetch], fetch_wait, write, write_wait, sincelaststats_elapsed_time, sincelaststats_work,
sincelaststats_cmds, sincelaststats_cmdspersec, sincelaststats_fetch, sincelaststats_fetch_wait, sincelaststats_write,
sincelaststats_write_wait, [time], agent_id, [type])
SELECT *, @time, @agent_id, @type
FROM OPENXML (@xmldoc, '/', 2)
WITH ([state] int 'stats/@state',
work int 'stats/@work',
idle int 'stats/@idle',
[fetch] int 'stats/reader/@fetch',
fetch_wait int 'stats/reader/@wait',
write int 'stats/writer/@write',
write_wait int 'stats/writer/@wait',
sincelaststats_elapsed_time int 'stats/sincelaststats/@elapsedtime',
sincelaststats_work int 'stats/sincelaststats/@work',
sincelaststats_cmds int 'stats/sincelaststats/@cmds',
sincelaststats_cmdspersec decimal 'stats/sincelaststats/@cmdspersec',
sincelaststats_fetch int 'stats/sincelaststats/reader/@fetch',
sincelaststats_fetch_wait int 'stats/sincelaststats/reader/@wait',
sincelaststats_write int 'stats/sincelaststats/writer/@write',
sincelaststats_write_wait int 'stats/sincelaststats/writer/@wait')
else if @getstate='2'
INSERT INTO [MS_ReplStats].[MS_perf_stats] ([state], [fetch], fetch_wait, cmds, callstogetreplcmds, sincelaststats_elapsed_time, sincelaststats_fetch, sincelaststats_fetch_wait, sincelaststats_cmds, sincelaststats_cmdspersec, [time], agent_id, [type])
SELECT *, @time, @agent_id, @type FROM OPENXML (@xmldoc, '/', 2)
WITH ([state] int 'stats/@state',
[fetch] int 'stats/@fetch',
fetch_wait int 'stats/@wait',
cmds int 'stats/@cmds',
callstogetreplcmds int 'stats/@callstogetreplcmds',
sincelaststats_elapsed_time int 'stats/sincelaststats/@elapsedtime',
sincelaststats_fetch int 'stats/sincelaststats/@fetch',
sincelaststats_fetch_wait int 'stats/sincelaststats/@wait',
sincelaststats_cmds int 'stats/sincelaststats/@cmds',
sincelaststats_cmdspersec decimal 'stats/sincelaststats/@cmdspersec')
else if @getstate='3'
INSERT INTO [MS_ReplStats].[MS_perf_stats]
([state], [write], write_wait, sincelaststats_elapsed_time, sincelaststats_write, sincelaststats_write_wait,
[time], agent_id, [type])
SELECT *, @time, @agent_id, @type from OPENXML (@xmldoc, '/', 2)
WITH ([state] int 'stats/@state',
[write] int 'stats/@write',
write_wait int 'stats/@wait',
sincelaststats_elapsed_time int 'stats/sincelaststats/@elapsedtime',
sincelaststats_write int 'stats/sincelaststats/@write',
sincelaststats_write_wait int 'stats/sincelaststats/@wait')
EXEC sp_xml_removedocument @xmldoc OUTPUT
GO
--execute permissions
GRANT EXECUTE ON [MS_ReplStats].[usp_MSINTERNAL_move_stats_to_table] TO public
GO
------------------------------------------------------------
-- Step 4) Create procedure usp_MSmove_stats_to_table used to
-- retrieve stats from Replication Agent history tables
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[MS_ReplStats].[usp_MSmove_stats_to_table]') AND type in (N'P', N'PC'))
DROP PROCEDURE [MS_ReplStats].[usp_MSmove_stats_to_table]
GO
CREATE PROCEDURE [MS_ReplStats].[usp_MSmove_stats_to_table] (@pubid int)
as
DECLARE @xpath nvarchar(500)
DECLARE @time datetime
DECLARE @agent_id int
DECLARE @type nvarchar(25)
DECLARE perfstats CURSOR for
SELECT lh.comments, lh.[time], lh.agent_id, 'LogRead'
FROM distribution..MSlogreader_history lh inner join distribution..MSlogreader_agents la
ON lh.agent_id=la.id WHERE la.publisher_id=@pubid and lh.comments like '<stats%'
UNION
SELECT dh.comments, dh.[time], dh.agent_id, 'Distrib'
FROM distribution..MSdistribution_history dh inner join distribution..MSdistribution_agents da
ON dh.agent_id=da.id WHERE da.publisher_id=@pubid and dh.comments like '<stats%'
OPEN perfstats
FETCH NEXT FROM perfstats INTO @xpath, @time, @agent_id, @type
WHILE (@@FETCH_STATUS <> -1)
BEGIN
IF (@@FETCH_STATUS <> -2)
BEGIN
SET NOCOUNT ON
EXEC [MS_ReplStats].[usp_MSINTERNAL_move_stats_to_table] @xpath, @time, @agent_id, @type
END
FETCH NEXT FROM perfstats INTO @xpath, @time, @agent_id, @type
END
CLOSE perfstats
DEALLOCATE perfstats
GO
--execute permissions
GRANT EXECUTE ON [MS_ReplStats].[usp_MSmove_stats_to_table] TO public
GO
------------------------------------------------------------
-- Step 5) Eexecute stored procedure usp_MSmove_stats_to_table
-- to extract Replicaton Agent stats.
--
-- Parameter 0 = publisher ID for Agents to extract.
-- Retrieve list of publisher_id values by executing
--
-- SELECT * FROM distribution.dbo.MSpublications
------------------------------------------------------------
EXEC [MS_ReplStats].[usp_MSmove_stats_to_table] 0
GO
------------------------------------------------------------
-- Step 6) Select history records to display performance stats
-- ORDER BY agent_id, time
------------------------------------------------------------
SELECT * FROM [MS_ReplStats].[MS_perf_stats]
ORDER BY time
--ORDER BY agent_id, time
--Query for LogReader Agent
SELECT * FROM [MS_ReplStats].[MS_perf_stats]
WHERE type='LogRead'
ORDER BY time
--Query for Distribution Agent(2)
SELECT * FROM [MS_ReplStats].[MS_perf_stats]
WHERE type='Distrib'
ORDER BY time
