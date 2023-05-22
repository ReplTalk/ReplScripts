--Distribution Database Replication Metadata Collection Script
-- Execute On Distributor
--Change as required:
--    Assumes Distribution database names is 'distribution'
--    Modify backup location below as needed

CREATE DATABASE MS_DistBackup
Go
ALTER DATABASE MS_DistBackup SET RECOVERY SIMPLE WITH NO_WAIT;
GO
USE distribution
go
-- For distribution DB +250gb range consider commenting next 4 select statements
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSrepl_commands]') AND type in (N'U'))
BEGIN
SELECT Top 100 * INTO MS_DistBackup..MSrepl_commands_OLDEST from Distribution..MSrepl_commands with (nolock)
	order by xact_seqno asc
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSrepl_commands]') AND type in (N'U'))
BEGIN
SELECT Top 100 * INTO MS_DistBackup..MSrepl_commands_NEWEST from Distribution..MSrepl_commands with (nolock)
	order by xact_seqno desc
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSrepl_transactions]') AND type in (N'U'))
BEGIN
SELECT top 100 * INTO MS_DistBackup..MSrepl_transactions_OLDEST from Distribution..MSrepl_transactions with (nolock)
	order by xact_seqno asc
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSrepl_transactions]') AND type in (N'U'))
BEGIN
SELECT top 100 * INTO MS_DistBackup..MSrepl_transactions_NEWEST from Distribution..MSrepl_transactions with (nolock)
	order by xact_seqno desc
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSarticles]') AND type in (N'U'))
BEGIN	
SELECT * INTO MS_DistBackup..MSarticles from Distribution..MSarticles with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MScached_peer_lsns]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MScached_peer_lsns from Distribution..MScached_peer_lsns with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSdistribution_agents]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSdistribution_agents from Distribution..MSdistribution_agents with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSdistribution_history]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSdistribution_history from Distribution..MSdistribution_history with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSlogreader_agents]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSlogreader_agents from Distribution..MSlogreader_agents with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSlogreader_history]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSlogreader_history from Distribution..MSlogreader_history with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_agents]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup.. MSmerge_agents from Distribution..MSmerge_agents with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_articlehistory]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSmerge_articlehistory from Distribution..MSmerge_articlehistory with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_history]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSmerge_history from Distribution..MSmerge_history with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_identity_range_allocations]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSmerge_identity_range_allocations from Distribution..MSmerge_identity_range_allocations with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_sessions]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSmerge_sessions from Distribution..MSmerge_sessions with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_subscriptions]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSmerge_subscriptions from Distribution..MSmerge_subscriptions with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSpublication_access]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSpublication_access from Distribution..MSpublication_access with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSpublications]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSpublications from Distribution..MSpublications with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSpublicationthresholds]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSpublicationthresholds from Distribution..MSpublicationthresholds with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSpublisher_databases]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSpublisher_databases from Distribution..MSpublisher_databases with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSqreader_agents]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSqreader_agents from Distribution..MSqreader_agents with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSqreader_history]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSqreader_history from Distribution..MSqreader_history with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSrepl_backup_lsns]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSrepl_backup_lsns from Distribution..MSrepl_backup_lsns with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSrepl_errors]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSrepl_errors from Distribution..MSrepl_errors with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSrepl_identity_range]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSrepl_identity_range from Distribution..MSrepl_identity_range with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSrepl_originators]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSrepl_originators from Distribution..MSrepl_originators with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSrepl_version]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSrepl_version from Distribution..MSrepl_version with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSreplication_monitordata]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSreplication_monitordata from Distribution..MSreplication_monitordata with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSsnapshot_agents]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSsnapshot_agents from Distribution..MSsnapshot_agents with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSsnapshot_history]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSsnapshot_history from Distribution..MSsnapshot_history with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSsubscriber_info]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSsubscriber_info from Distribution..MSsubscriber_info with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSsubscriber_schedule]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSsubscriber_schedule from Distribution..MSsubscriber_schedule with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSsubscriptions]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSsubscriptions from Distribution..MSsubscriptions with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSsync_states]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MSsync_states from Distribution..MSsync_states with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MStracer_history]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MStracer_history from Distribution..MStracer_history with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MStracer_tokens]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..MStracer_tokens from Distribution..MStracer_tokens with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSredirected_publishers]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..[MSredirected_publishers] from Distribution..[MSredirected_publishers] with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSrepl_agent_jobs]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..[MSrepl_agent_jobs] from Distribution..[MSrepl_agent_jobs] with (nolock)
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSreplservers]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_DistBackup..[MSreplservers] from Distribution..[MSreplservers] with (nolock)
END
GO
 
--Change backup location if needed.
BACKUP DATABASE MS_DistBackup to disk='C:\DBBackup\MS_DistBackup.bak'
Go