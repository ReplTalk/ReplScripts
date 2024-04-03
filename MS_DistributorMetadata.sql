--distribution Database Replication Metadata Collection Script
-- Execute On Distributor
--Change as required:
--    Assumes distribution database names is 'distribution'
--    Modify backup location below as needed

CREATE DATABASE MS_DistBackup
Go
ALTER DATABASE MS_DistBackup SET RECOVERY SIMPLE WITH NO_WAIT;
GO
USE MS_DistBackup
go
-- For distribution DB +250gb range consider commenting next 4 select statements
SELECT Top 100 * INTO MSrepl_commands_OLDEST from distribution..MSrepl_commands with (nolock)
	order by xact_seqno asc
SELECT Top 100 * INTO MSrepl_commands_NEWEST from distribution..MSrepl_commands with (nolock)
	order by xact_seqno desc
SELECT top 100 * INTO MSrepl_transactions_OLDEST from distribution..MSrepl_transactions with (nolock)
	order by xact_seqno asc
SELECT top 100 * INTO MSrepl_transactions_NEWEST from distribution..MSrepl_transactions with (nolock)
	order by xact_seqno desc
	
SELECT * INTO MSarticles from distribution..MSarticles with (nolock)
SELECT * INTO MScached_peer_lsns from distribution..MScached_peer_lsns with (nolock)
SELECT * INTO MSdistribution_agents from distribution..MSdistribution_agents with (nolock)
SELECT * INTO MSdistribution_history from distribution..MSdistribution_history with (nolock)
SELECT * INTO MSlogreader_agents from distribution..MSlogreader_agents with (nolock)
SELECT * INTO MSlogreader_history from distribution..MSlogreader_history with (nolock)
SELECT * INTO MSmerge_agents from distribution..MSmerge_agents with (nolock)
SELECT * INTO MSmerge_articlehistory from distribution..MSmerge_articlehistory with (nolock)
SELECT * INTO MSmerge_history from distribution..MSmerge_history with (nolock)
SELECT * INTO MSmerge_identity_range_allocations from distribution..MSmerge_identity_range_allocations with (nolock)
SELECT * INTO MSmerge_sessions from distribution..MSmerge_sessions with (nolock)
SELECT * INTO MSmerge_subscriptions from distribution..MSmerge_subscriptions with (nolock)
SELECT * INTO MSpublication_access from distribution..MSpublication_access with (nolock)
SELECT * INTO MSpublications from distribution..MSpublications with (nolock)
SELECT * INTO MSpublicationthresholds from distribution..MSpublicationthresholds with (nolock)
SELECT * INTO MSpublisher_databases from distribution..MSpublisher_databases with (nolock)
SELECT * INTO MSqreader_agents from distribution..MSqreader_agents with (nolock)
SELECT * INTO MSqreader_history from distribution..MSqreader_history with (nolock)
SELECT * INTO MSrepl_backup_lsns from distribution..MSrepl_backup_lsns with (nolock)
SELECT * INTO MSrepl_errors from distribution..MSrepl_errors with (nolock)
SELECT * INTO MSrepl_identity_range from distribution..MSrepl_identity_range with (nolock)
SELECT * INTO MSrepl_originators from distribution..MSrepl_originators with (nolock)
SELECT * INTO MSrepl_version from distribution..MSrepl_version with (nolock)
SELECT * INTO MSreplication_monitordata from distribution..MSreplication_monitordata with (nolock)
SELECT * INTO MSsnapshot_agents from distribution..MSsnapshot_agents with (nolock)
SELECT * INTO MSsnapshot_history from distribution..MSsnapshot_history with (nolock)
SELECT * INTO MSsubscriber_info from distribution..MSsubscriber_info with (nolock)
SELECT * INTO MSsubscriber_schedule from distribution..MSsubscriber_schedule with (nolock)
SELECT * INTO MSsubscriptions from distribution..MSsubscriptions with (nolock)
SELECT * INTO MSsync_states from distribution..MSsync_states with (nolock)
SELECT * INTO MStracer_history from distribution..MStracer_history with (nolock)
SELECT * INTO MStracer_tokens from distribution..MStracer_tokens with (nolock)

SELECT * INTO [MSredirected_publishers] from distribution..[MSredirected_publishers] with (nolock)
SELECT * INTO [MSrepl_agent_jobs] from distribution..[MSrepl_agent_jobs] with (nolock)
SELECT * INTO [MSreplservers] from distribution..[MSreplservers] with (nolock)

--msdb tables 

SELECT aprof.*, aparam.parameter_name, aparam.value 
INTO MSagent_profiles_parameters 
FROM msdb..MSagent_profiles aprof WITH(NOLOCK)
	INNER JOIN msdb..MSagent_parameters aparam WITH(NOLOCK)
		ON (aprof.profile_id = aparam.profile_id)

SELECT * INTO MSdistpublishers FROM msdb..MSdistpublishers WITH(NOLOCK)

Go
 
--Change backup location if needed.
BACKUP DATABASE MS_DistBackup to disk='c:\MS_DistBackup.bak'
Go

