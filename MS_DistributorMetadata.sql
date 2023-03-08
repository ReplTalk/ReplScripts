--Distribution Database Replication Metadata Collection Script
-- Execute On Distributor
--Change as required:
--    Assumes Distribution database names is 'distribution'
--    Modify backup location below as needed

CREATE DATABASE MS_DistBackup
Go
ALTER DATABASE MS_DistBackup SET RECOVERY SIMPLE WITH NO_WAIT;
GO
USE MS_DistBackup
go
-- For distribution DB +250gb range consider commenting next 4 select statements
SELECT Top 100 * INTO MSrepl_commands_OLDEST from Distribution..MSrepl_commands with (nolock)
	order by xact_seqno asc
SELECT Top 100 * INTO MSrepl_commands_NEWEST from Distribution..MSrepl_commands with (nolock)
	order by xact_seqno desc
SELECT top 100 * INTO MSrepl_transactions_OLDEST from Distribution..MSrepl_transactions with (nolock)
	order by xact_seqno asc
SELECT top 100 * INTO MSrepl_transactions_NEWEST from Distribution..MSrepl_transactions with (nolock)
	order by xact_seqno desc
	
SELECT * INTO MSarticles from Distribution..MSarticles with (nolock)
SELECT * INTO MScached_peer_lsns from Distribution..MScached_peer_lsns with (nolock)
SELECT * INTO MSdistribution_agents from Distribution..MSdistribution_agents with (nolock)
SELECT * INTO MSdistribution_history from Distribution..MSdistribution_history with (nolock)
SELECT * INTO MSlogreader_agents from Distribution..MSlogreader_agents with (nolock)
SELECT * INTO MSlogreader_history from Distribution..MSlogreader_history with (nolock)
SELECT * INTO MSmerge_agents from Distribution..MSmerge_agents with (nolock)
SELECT * INTO MSmerge_articlehistory from Distribution..MSmerge_articlehistory with (nolock)
SELECT * INTO MSmerge_history from Distribution..MSmerge_history with (nolock)
SELECT * INTO MSmerge_identity_range_allocations from Distribution..MSmerge_identity_range_allocations with (nolock)
SELECT * INTO MSmerge_sessions from Distribution..MSmerge_sessions with (nolock)
SELECT * INTO MSmerge_subscriptions from Distribution..MSmerge_subscriptions with (nolock)
SELECT * INTO MSpublication_access from Distribution..MSpublication_access with (nolock)
SELECT * INTO MSpublications from Distribution..MSpublications with (nolock)
SELECT * INTO MSpublicationthresholds from Distribution..MSpublicationthresholds with (nolock)
SELECT * INTO MSpublisher_databases from Distribution..MSpublisher_databases with (nolock)
SELECT * INTO MSqreader_agents from Distribution..MSqreader_agents with (nolock)
SELECT * INTO MSqreader_history from Distribution..MSqreader_history with (nolock)
SELECT * INTO MSrepl_backup_lsns from Distribution..MSrepl_backup_lsns with (nolock)
SELECT * INTO MSrepl_errors from Distribution..MSrepl_errors with (nolock)
SELECT * INTO MSrepl_identity_range from Distribution..MSrepl_identity_range with (nolock)
SELECT * INTO MSrepl_originators from Distribution..MSrepl_originators with (nolock)
SELECT * INTO MSrepl_version from Distribution..MSrepl_version with (nolock)
SELECT * INTO MSreplication_monitordata from Distribution..MSreplication_monitordata with (nolock)
SELECT * INTO MSsnapshot_agents from Distribution..MSsnapshot_agents with (nolock)
SELECT * INTO MSsnapshot_history from Distribution..MSsnapshot_history with (nolock)
SELECT * INTO MSsubscriber_info from Distribution..MSsubscriber_info with (nolock)
SELECT * INTO MSsubscriber_schedule from Distribution..MSsubscriber_schedule with (nolock)
SELECT * INTO MSsubscriptions from Distribution..MSsubscriptions with (nolock)
SELECT * INTO MSsync_states from Distribution..MSsync_states with (nolock)
SELECT * INTO MStracer_history from Distribution..MStracer_history with (nolock)
SELECT * INTO MStracer_tokens from Distribution..MStracer_tokens with (nolock)

SELECT * INTO [MSredirected_publishers] from Distribution..[MSredirected_publishers] with (nolock)
SELECT * INTO [MSrepl_agent_jobs] from Distribution..[MSrepl_agent_jobs] with (nolock)
SELECT * INTO [MSreplservers] from Distribution..[MSreplservers] with (nolock)
Go
 
--Change backup location if needed.
BACKUP DATABASE MS_DistBackup to disk='c:\MS_DistBackup.bak'
Go

