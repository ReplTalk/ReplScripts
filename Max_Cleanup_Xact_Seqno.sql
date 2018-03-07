set nocount on
declare	@publisher_database_id int,
	    @min_cutoff_time datetime,
	    @max_cleanup_xact_seqno varbinary(16),
		@retention int, 
		@rptdtl int 

select @retention = 72  --If the retention period has been changed, then update this to that value
select @publisher_database_id = NULL  --if you want to look for specific database, change this from NULL to value from MSPublisher_databases table.
select @rptdtl = 2  --if you want more information about agents keeping the xact_seqno to a minimum, change this to 2.
select @min_cutoff_time = dateadd(hour, -@retention, getdate())

declare @min_agent_sub_xact_seqno varbinary(16)
		,@max_agent_hist_xact_seqno varbinary(16)
		,@active int
		,@initiated int
		,@agent_id int
		,@min_xact_seqno varbinary(16)

--Loop through each database
if @publisher_database_id is null
begin
   declare pub_db scroll cursor for  
   select id from MSpublisher_databases    
end
else
begin
   declare pub_db scroll cursor for  
   select id from MSpublisher_databases 
   where id = @publisher_database_id
end

open pub_db

fetch first from pub_db into @publisher_database_id      
while @@FETCH_STATUS = 0
begin      

	-- set @min_xact_seqno to NULL and reset it with the first prospect of min_seqno we found later
select @min_xact_seqno = NULL
select @active = 2
select @initiated = 3

	--
	-- cursor through each agent with it's smallest sub xact seqno
	--
declare #tmpAgentSubSeqno cursor local forward_only  for
select a.id, min(s2.subscription_seqno) from MSsubscriptions s2 join MSdistribution_agents a
on (a.id = s2.agent_id) 
where s2.status in( @active, @initiated ) and
	                        /* Note must filter out virtual anonymous agents !!!
                                      a.subscriber_id <> @virtual_anonymous and */
                            -- filter out subscriptions to immediate_sync publications
not exists (select * from MSpublications p 
            where s2.publication_id = p.publication_id 
			 and p.immediate_sync = 1) 
and a.publisher_database_id = @publisher_database_id
group by a.id

open #tmpAgentSubSeqno 

fetch #tmpAgentSubSeqno into @agent_id, @min_agent_sub_xact_seqno 
	
if (@@fetch_status = -1) -- rowcount = 0 (no subscriptions)
begin
        -- If we have a publication which allows for init from backup with a min_autonosync_lsn set
        --   we don't want this proc to signal cleanup of all commands
        -- Note that if we filter out immediate_sync publications here as they will already have the
        --   desired outcome.  The difference is that those with min_autonosync_lsn set have a watermark
        --   at which to begin blocking cleanup.
	if not exists (select * from dbo.MSpublications msp join MSpublisher_databases mspd 
	               ON mspd.publisher_id = msp.publisher_id 
                    and mspd.publisher_db = msp.publisher_db
                   where mspd.id = @publisher_database_id 
				    and msp.immediate_sync = 1)
	begin
       select top(1) @min_xact_seqno = msp.min_autonosync_lsn from dbo.MSpublications msp join MSpublisher_databases mspd 
	   ON mspd.publisher_id = msp.publisher_id 
       and mspd.publisher_db = msp.publisher_db
       where mspd.id = @publisher_database_id 
        and msp.allow_initialize_from_backup <> 0
         and msp.min_autonosync_lsn is not null
          and msp.immediate_sync = 0
	   order by msp.min_autonosync_lsn asc
	end
 end

 while (@@fetch_status <> -1)
 begin
	    --
	    --always clear the local variable, next query may not return any resultset
	    --
    set @max_agent_hist_xact_seqno = NULL
	    --
	    --find last history entry for current agent, if no history then the query below should leave @max_agent_xact_seqno as NULL
	    --
    select top 1 @max_agent_hist_xact_seqno = xact_seqno from MSdistribution_history 
	where agent_id = @agent_id 
	order by timestamp desc

    if @rptdtl = 2
    begin
       select @publisher_database_id as Pub_DB_ID,@agent_id as AgentID,@max_agent_hist_xact_seqno as Max_Agent_Hist_Xact_Seqno,
	          @min_agent_sub_xact_seqno as Min_Agent_Sub_Xact_Seqno
    end
	    --
	    --now find the last xact_seqno this agent has delivered:
	    --if last history was written after initsync, use histry xact_seqno otherwise use initsync xact_seqno        
	    --
	if isnull(@max_agent_hist_xact_seqno, @min_agent_sub_xact_seqno) <= @min_agent_sub_xact_seqno 
	begin
	   set @max_agent_hist_xact_seqno = @min_agent_sub_xact_seqno
	end
	    --@min_xact_seqno was set to NULL to start with, the first time we get here, it'll gets set to a non-NULL value
	    --then we graduately move to the smallest hist/sub seqno
	if ((@min_xact_seqno is null) or (@min_xact_seqno > @max_agent_hist_xact_seqno))
	begin 
	   set @min_xact_seqno = @max_agent_hist_xact_seqno 
	end
    fetch #tmpAgentSubSeqno into @agent_id, @min_agent_sub_xact_seqno 
 end
 close #tmpAgentSubSeqno
 deallocate #tmpAgentSubSeqno
	/* 
	** Optimized query to get the maximum cleanup xact_seqno
	*/
	/* 
	** If the query below returns nothing, nothing can be deleted.
	** Reset @max_cleanup_xact_seqno to 0.
	*/
 select @max_cleanup_xact_seqno = 0x00
	-- Use top 1 to avoid warning message of "Null in aggregate..." which will make
	-- sqlserver agent job having failing status

   if @min_xact_seqno is NULL and @rptdtl = 2 and @agent_id is NULL
   begin
      select @publisher_database_id as Pub_DB_ID, 'No immediate sync publications, so is not dependent on Agent History'
   end
   select top 1 @max_cleanup_xact_seqno = xact_seqno from MSrepl_transactions with (nolock)
   where publisher_database_id = @publisher_database_id 
   and (xact_seqno < @min_xact_seqno
   or @min_xact_seqno IS NULL) 
   and entry_time <= @min_cutoff_time
   order by xact_seqno desc

   select @publisher_database_id as Pub_DB_ID, @max_cleanup_xact_seqno as Max_Cleanup_Xact_Seqno

   fetch next from pub_db into @publisher_database_id    
end

close pub_db
deallocate pub_db

/*

Example Output:

Pub_DB_ID   AgentID     Max_Agent_Hist_Xact_Seqno          Min_Agent_Sub_Xact_Seqno
----------- ----------- ---------------------------------- ----------------------------------
1           1           0x0000003B000000EF0008000000000000 0x0000003A00000198000300000001

Pub_DB_ID   AgentID     Max_Agent_Hist_Xact_Seqno          Min_Agent_Sub_Xact_Seqno
----------- ----------- ---------------------------------- ----------------------------------
1           2           0x0000003B0000015A0004000000000000 0x0000003B000000CE0049

Pub_DB_ID   Max_Cleanup_Xact_Seqno
----------- ----------------------------------
1           0x0000003B000000DE005C

*/
