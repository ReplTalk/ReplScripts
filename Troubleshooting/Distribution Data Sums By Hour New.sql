use distribution
go

-- VERY INTENSIVE OUTPUT: See All commands and Transactions

-- select t.xact_seqno, c.xact_seqno, c.publisher_database_id 

-- FROM MSrepl_commands c with (nolock)

-- LEFT JOIN  msrepl_transactions t with (nolock)

--      on t.publisher_database_id = c.publisher_database_id 

--      and t.xact_seqno = c.xact_seqno

 

-- Check the Time associated with those commands and save into temp table

select t.publisher_database_id, t.xact_seqno, 
      max(t.entry_time) as EntryTime, count(c.xact_seqno) as CommandCount
into #results
FROM MSrepl_commands c with (nolock)
LEFT JOIN  msrepl_transactions t with (nolock)
      on t.publisher_database_id = c.publisher_database_id 
      and t.xact_seqno = c.xact_seqno
GROUP BY t.publisher_database_id, t.xact_seqno
 

 

---- show all results
--select * from #results
--order by publisher_database_id, xact_seqno
 

-- Find large transactions

select top 1000 * from #results 
where CommandCount > 1000
order by CommandCount desc --publisher_database_id, xact_seqno

 

-- Do a quick report on the results of above to show each hour and number of commands per Day:

select publisher_database_id, datepart(year, EntryTime) as Year, datepart(month, EntryTime) as Month, 
datepart(day, EntryTime) as Day,-- datepart(hh, EntryTime) as Hour,
--datepart(mi, EntryTime) as Minute, datepart(ss, EntryTime) as Second,
sum(CommandCount) as CommandCountPerTimeUnit
from #results
group by publisher_database_id,
datepart(year, EntryTime), datepart(month, EntryTime), 
datepart(day, EntryTime)--, datepart(hh, EntryTime),
-- datepart(mi, EntryTime), datepart(ss, EntryTime)
order by publisher_database_id, sum(CommandCount) Desc


