------------------------------------------------------------
-- Create stored procedure sp_endtoend_stats to
-- select complete history from a given poin in time.
--
-- Written by: Curt Mathews
-- Modified by: Chris Skorlinski
--
-- Paramter @startpoint datetime
------------------------------------------------------------
/****** Object: StoredProcedure [MS_ReplStats].sp_endtoend_stats Script Date: 03/22/2009 14:27:37 ******/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[MS_ReplStats].sp_endtoend_stats') AND type in (N'P', N'PC'))
DROP PROCEDURE [MS_ReplStats].sp_endtoend_stats
GO
CREATE PROCEDURE [MS_ReplStats].sp_endtoend_stats (@startpoint datetime)
as
CREATE TABLE [#logread]([id] int identity(1,1), [state] [int] NULL, [work] [int] NULL, [idle] [int] NULL,
[num_fetch] [int] NULL, [fetch_wait] [int] NULL, [num_write] [int] NULL, [write_wait] [int] NULL,
[sincelaststats_elapsed_time] [int] NULL, [sincelaststats_work] [int] NULL, [sincelaststats_cmds] [int] NULL,
[sincelaststats_cmdspersec] [numeric](18, 0) NULL, [sincelaststats_num_fetch] [int] NULL, [sincelaststats_fetch_wait] [int] NULL,
[sincelaststats_num_write] [int] NULL, [sincelaststats_write_wait] [int] NULL, [time] [datetime] NULL, [type] [nvarchar] (25) NULL
) ON [PRIMARY]
CREATE TABLE [#distrib]([id] int identity(1,1), [state] [int] NULL, [work] [int] NULL, [idle] [int] NULL,
[num_fetch] [int] NULL, [fetch_wait] [int] NULL, [num_write] [int] NULL, [write_wait] [int] NULL,
[sincelaststats_elapsed_time] [int] NULL, [sincelaststats_work] [int] NULL, [sincelaststats_cmds] [int] NULL,
[sincelaststats_cmdspersec] [numeric](18, 0) NULL, [sincelaststats_num_fetch] [int] NULL, [sincelaststats_fetch_wait] [int] NULL,
[sincelaststats_num_write] [int] NULL, [sincelaststats_write_wait] [int] NULL, [time] [datetime] NULL, [type] [nvarchar] (25) NULL
) ON [PRIMARY]
INSERT INTO [#logread]
([state],[work],[idle],[num_fetch],[fetch_wait],[num_write],[write_wait]
,[sincelaststats_elapsed_time],[sincelaststats_work]
,[sincelaststats_cmds],[sincelaststats_cmdspersec]
,[sincelaststats_num_fetch],[sincelaststats_fetch_wait]
,[sincelaststats_num_write],[sincelaststats_write_wait]
,[time],[type])
SELECT [state],[work],[idle],[fetch],[fetch_wait],[write],[write_wait]
,[sincelaststats_elapsed_time],[sincelaststats_work]
,[sincelaststats_cmds],[sincelaststats_cmdspersec]
,[sincelaststats_fetch],[sincelaststats_fetch_wait]
,[sincelaststats_write],[sincelaststats_write_wait]
,[time],[type]
FROM [MS_ReplStats].[MS_perf_stats]
WHERE time>=@startpoint and type='LogRead' ORDER BY time
INSERT INTO #distrib([state],[work],[idle],[num_fetch],[fetch_wait],[num_write],[write_wait]
,[sincelaststats_elapsed_time],[sincelaststats_work]
,[sincelaststats_cmds],[sincelaststats_cmdspersec]
,[sincelaststats_num_fetch],[sincelaststats_fetch_wait]
,[sincelaststats_num_write],[sincelaststats_write_wait]
,[time],[type])
SELECT [state],[work],[idle],[fetch],[fetch_wait],[write],[write_wait]
,[sincelaststats_elapsed_time],[sincelaststats_work]
,[sincelaststats_cmds],[sincelaststats_cmdspersec]
,[sincelaststats_fetch],[sincelaststats_fetch_wait]
,[sincelaststats_write],[sincelaststats_write_wait]
,[time],[type]
FROM [MS_ReplStats].[MS_perf_stats]
WHERE time>=@startpoint and type='Distrib' ORDER BY time
--join LogReader and Distributor stats
SELECT 'ID'=l.id, 'LogRead Work'=l.work, 'Distrib Work'=d.work, 'LogRead Idle'=l.idle,
'Distrib Idle'=d.idle, 'LogRead Work SinceLastStats'=l.[sincelaststats_work],
'Distrib Work SinceLastStats'=d.[sincelaststats_work], 'LogRead SinceLastStats Cmds'=l.[sincelaststats_cmds],
'Distrib SinceLastStats Cmds'=d.[sincelaststats_cmds], 'LogRead SinceLastStats Cmds Per Sec'=l.[sincelaststats_cmdspersec],
'Distrib SinceLastStats Cmds Per Sec'=d.[sincelaststats_cmdspersec], 'LogRead SinceLastStats Num Fetch'=l.[sincelaststats_num_fetch],
'Distrib SinceLastStats Num Fetch'=d.[sincelaststats_num_fetch], 'LogRead SinceLastStats Fetch Wait'=l.[sincelaststats_fetch_wait],
'Distrib SinceLastStats Fetch Wait'=d.[sincelaststats_fetch_wait], 'LogRead SinceLastStats Num Write'=l.[sincelaststats_num_write],
'Distrib SinceLastStats Num Write'=d.[sincelaststats_num_write], 'LogRead SinceLastStats Write Wait'=l.[sincelaststats_write_wait],
'Distrib SinceLastStats Write Wait'=d.[sincelaststats_write_wait], 'LogRead Time'=l.time, 'Distrib Time'=d.time
FROM #logread l JOIN #distrib d ON l.id=d.id ORDER BY l.id
GO
------------------------------------------------------------
-- Execute stored procedure sp_endtoend_stats to
-- return complete history from a given poin in time.
--
-- Paramter @startpoint datetime
------------------------------------------------------------
exec [MS_ReplStats].sp_endtoend_stats '2009-06-01 00:03:24.340'
GO
