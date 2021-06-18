/*
Table perf_stats_tab contains both logreader and distrib perf stats that can be
queried independently by using WHERE TYPE='Distrib' or WHERE TYPE='LogRead'
*/
DROP TABLE perf_stats_tab
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[perf_stats_tab](
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
/*
Procedure sp_move_stats_to_tab opens a cursor on table mslogreader_history and
msdistribution_history and then, for each row, calls procedure move_stats_to_tab
to extract the xml stats data into table perf_stats_tab.
*/
DROP PROCEDURE move_stats_to_tab
GO
CREATE PROCEDURE move_stats_to_tab (@xpath nvarchar(500), @time datetime, @agent_id int, @type nvarchar(25))
AS
declare @xmldoc int
exec sp_xml_preparedocument @xmldoc OUTPUT, @xpath
declare @getstate varchar(1)
select @getstate=SUBSTRING ( @xpath, 15 , 1)
if @getstate='1'
insert into perf_stats_tab ([state], work, idle, [fetch], fetch_wait, write, write_wait, sincelaststats_elapsed_time, sincelaststats_work, sincelaststats_cmds, sincelaststats_cmdspersec, sincelaststats_fetch, sincelaststats_fetch_wait, sincelaststats_write, sincelaststats_write_wait, [time], agent_id, [type])
select *, @time, @agent_id, @type from OPENXML (@xmldoc, '/', 2)
with ([state] int 'stats/@state',
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
insert into perf_stats_tab ([state], [fetch], fetch_wait, cmds, callstogetreplcmds, sincelaststats_elapsed_time, sincelaststats_fetch, sincelaststats_fetch_wait, sincelaststats_cmds, sincelaststats_cmdspersec, [time], agent_id, [type])
select *, @time, @agent_id, @type from OPENXML (@xmldoc, '/', 2)
with ([state] int 'stats/@state',
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
insert into perf_stats_tab ([state], [write], write_wait, sincelaststats_elapsed_time, sincelaststats_write, sincelaststats_write_wait, [time], agent_id, [type])
select *, @time, @agent_id, @type from OPENXML (@xmldoc, '/', 2)
with ([state] int 'stats/@state',
[write] int 'stats/@write',
write_wait int 'stats/@wait',
sincelaststats_elapsed_time int 'stats/sincelaststats/@elapsedtime',
sincelaststats_write int 'stats/sincelaststats/@write',
sincelaststats_write_wait int 'stats/sincelaststats/@wait')
exec sp_xml_removedocument @xmldoc OUTPUT
GO
DROP PROCEDURE sp_move_stats_to_tab
GO
CREATE PROCEDURE sp_move_stats_to_tab (@pubid int)
as
declare @xpath nvarchar(500)
declare @time datetime
declare @agent_id int
declare @type nvarchar(25)
declare perfstats CURSOR for
SELECT lh.Comments, lh.[Time], lh.agent_id, 'LogRead' from distribution..mslogreader_history lh inner join distribution..mslogreader_agents la
on lh.agent_id=la.id where la.publisher_id=@pubid and lh.Comments like '<stats%'
UNION
SELECT dh.Comments, dh.[Time], dh.agent_id, 'Distrib' from distribution..msdistribution_history dh inner join distribution..msdistribution_agents da
on dh.agent_id=da.id where da.publisher_id=@pubid and dh.Comments like '<stats%'
OPEN perfstats
FETCH NEXT FROM perfstats INTO @xpath, @time, @agent_id, @type
WHILE (@@FETCH_STATUS <> -1)
BEGIN
IF (@@FETCH_STATUS <> -2)
BEGIN
exec move_stats_to_tab @xpath, @time, @agent_id, @type
END
FETCH NEXT FROM perfstats INTO @xpath, @time, @agent_id, @type
END
CLOSE perfstats
DEALLOCATE perfstats
--execute the procedure - pass in the publisher id of the publication whose logreader and distribution agents are to be
--queried for
EXEC sp_move_stats_to_tab 0
GO
--Query State 1 Data for LogReader Agent
SELECT * FROM perf_stats_tab
where type='LogRead'
and state=1
ORDER BY TIME
--Query State 2 Data for Distribution Agent
SELECT state, [fetch], fetch_wait, cmds, callstogetreplcmds, sincelaststats_elapsed_time, sincelaststats_fetch, sincelaststats_fetch_wait, sincelaststats_cmds, sincelaststats_cmdspersec FROM perf_stats_tab
where type='Distrib'
and state=2
ORDER BY TIME
GO
