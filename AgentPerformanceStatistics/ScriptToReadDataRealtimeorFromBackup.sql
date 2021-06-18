
-- General data list
select
h.time
,a.Publication
--<stats>
,(CAST ([comments] as xml)).value('(/stats/@state)[1]', 'int') AS [state]
,(CAST ([comments] as xml)).value('(/stats/@work)[1]', 'int') AS [work]
,(CAST ([comments] as xml)).value('(/stats/@idle)[1]', 'int') AS [idle]
--<stats><reader>
,(CAST ([comments] as xml)).value('(/stats/reader/@fetch)[1]', 'int') AS [reader fetch]
,(CAST ([comments] as xml)).value('(/stats/reader/@wait)[1]', 'int') AS [reader write]
--<stats><writer>
,(CAST ([comments] as xml)).value('(/stats/writer/@write)[1]', 'int') AS [writer write]
,(CAST ([comments] as xml)).value('(/stats/writer/@wait)[1]', 'int') AS [writer wait]
--<stats><sincelaststats>
,(CAST ([comments] as xml)).value('(/stats/sincelaststats/@elapsedtime)[1]', 'int') AS [sincelaststats elapsedtime]
,(CAST ([comments] as xml)).value('(/stats/sincelaststats/@work)[1]', 'int') AS [sincelaststats work]
,(CAST ([comments] as xml)).value('(/stats/sincelaststats/@cmds)[1]', 'int') AS [sincelaststats cmds]
,(CAST ([comments] as xml)).value('(/stats/sincelaststats/@cmdspersec)[1]', 'float') AS [sincelaststats cmdspersec]
--<stats><sincelaststats><reader>
,(CAST ([comments] as xml)).value('(/stats/sincelaststats/reader/@fetch)[1]', 'int') AS [sincelaststats reader fetch]
,(CAST ([comments] as xml)).value('(/stats/sincelaststats/reader/@wait)[1]', 'int') AS [sincelaststats reader write]
--<stats><sincelaststats><writer>
,(CAST ([comments] as xml)).value('(/stats/sincelaststats/writer/@write)[1]', 'int') AS [sincelaststats writer write]
,(CAST ([comments] as xml)).value('(/stats/sincelaststats/writer/@wait)[1]', 'int') AS [sincelaststats writer wait]
from MSdistribution_history h
join MSdistribution_agents a
on h.agent_id = a.id
where
h.[comments] like '<stats%'
order by h.time
-- For a specific subscriber accumulate by second for all publications by publication
-- In this case the cummlative makes sense as we accumulate by agent/publication
select
[Publication] = a.Publication
,[Timeframe] = CONVERT(char(16),h.time,20 )
--<stats>
,avg((CAST ([comments] as xml)).value('(/stats/@state)[1]', 'bigint')) AS [state]
,sum((CAST ([comments] as xml)).value('(/stats/@work)[1]', 'bigint')) AS [work]
,sum((CAST ([comments] as xml)).value('(/stats/@idle)[1]', 'bigint')) AS [idle]
--<stats><reader>
,sum((CAST ([comments] as xml)).value('(/stats/reader/@fetch)[1]', 'bigint')) AS [reader_fetch]
,sum((CAST ([comments] as xml)).value('(/stats/reader/@wait)[1]', 'bigint')) AS [reader_wait]
--<stats><writer>
,sum((CAST ([comments] as xml)).value('(/stats/writer/@write)[1]', 'bigint')) AS [writer_write]
,sum((CAST ([comments] as xml)).value('(/stats/writer/@wait)[1]', 'bigint')) AS [writer_wait]
--<stats><sincelaststats>
,sum((CAST ([comments] as xml)).value('(/stats/sincelaststats/@elapsedtime)[1]', 'bigint')) AS [sincelaststats_elapsedtime]
,sum((CAST ([comments] as xml)).value('(/stats/sincelaststats/@work)[1]', 'bigint')) AS [sincelaststats_work]
,sum((CAST ([comments] as xml)).value('(/stats/sincelaststats/@cmds)[1]', 'bigint')) AS [sincelaststats_cmds]
,avg((CAST ([comments] as xml)).value('(/stats/sincelaststats/@cmdspersec)[1]', 'float')) AS [sincelaststats_cmdspersec]
--<stats><sincelaststats><reader>
,sum((CAST ([comments] as xml)).value('(/stats/sincelaststats/reader/@fetch)[1]', 'bigint')) AS [sincelaststats_reader_fetch]
,sum((CAST ([comments] as xml)).value('(/stats/sincelaststats/reader/@wait)[1]', 'bigint')) AS [sincelaststats_reader_wait]
--<stats><sincelaststats><writer>
,sum((CAST ([comments] as xml)).value('(/stats/sincelaststats/writer/@write)[1]', 'bigint')) AS [sincelaststats_writer_write]
,sum((CAST ([comments] as xml)).value('(/stats/sincelaststats/writer/@wait)[1]', 'bigint')) AS [sincelaststats_writer_wait]
from MSdistribution_history h
join MSdistribution_agents a
on h.agent_id = a.id
where
a.name like '%EMACAMMSQ06%' -- change the subscriber here (alternatively get the subscriber ID which I didn't have)
and h.[comments] like '<stats%'
group by a.Publication,CONVERT(char(16),h.time,20 )
order by a.Publication,CONVERT(char(16),h.time,20 )
-- For a specific subscriber accumulate by second for all publications per time interval
-- In this case the cummlative fields do NOT make sense as the replication code accumulates these values by agent and we do not want to list by agent
-- This query accummulates by date only (puts all publications / agents ID together for that subscriber)
select
[Timeframe] = CONVERT(char(16),h.time,20 )
--<stats><sincelaststats>
,sum((CAST ([comments] as xml)).value('(/stats/sincelaststats/@elapsedtime)[1]', 'bigint')) AS [sincelaststats_elapsedtime]
,sum((CAST ([comments] as xml)).value('(/stats/sincelaststats/@work)[1]', 'bigint')) AS [sincelaststats_work]
,sum((CAST ([comments] as xml)).value('(/stats/sincelaststats/@cmds)[1]', 'bigint')) AS [sincelaststats_cmds]
,avg((CAST ([comments] as xml)).value('(/stats/sincelaststats/@cmdspersec)[1]', 'float')) AS [sincelaststats_cmdspersec]
--<stats><sincelaststats><reader>
,sum((CAST ([comments] as xml)).value('(/stats/sincelaststats/reader/@fetch)[1]', 'bigint')) AS [sincelaststats_reader_fetch]
,sum((CAST ([comments] as xml)).value('(/stats/sincelaststats/reader/@wait)[1]', 'bigint')) AS [sincelaststats_reader_wait]
--<stats><sincelaststats><writer>
,sum((CAST ([comments] as xml)).value('(/stats/sincelaststats/writer/@write)[1]', 'bigint')) AS [sincelaststats_writer_write]
,sum((CAST ([comments] as xml)).value('(/stats/sincelaststats/writer/@wait)[1]', 'bigint')) AS [sincelaststats_writer_wait]
from MSdistribution_history h
join MSdistribution_agents a
on h.agent_id = a.id
where
a.name like '%EMACAMMSQ06%' -- change the subscriber here (alternatively get the subscriber ID which I didn't have)
and h.[comments] like '<stats%'
and (CAST([comments] as xml)).value('(/stats/@state)[1]', 'bigint') = 1 -- Only complete stats
-- fix an interval for comparison
and h.time >= '2010-12-13 00:00'
group by CONVERT(char(16),h.time,20 )
order by CONVERT(char(16),h.time,20 )
