--Execute on the Subscriber database
--

create database MS_SubscriberMetadata
go

ALTER DATABASE MS_SubscriberMetadata SET RECOVERY SIMPLE WITH NO_WAIT;
GO

Use <replace with published database name>
go

--Merge Replication Tables
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSsnapshotdeliveryprogress]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSsnapshotdeliveryprogress FROM dbo.MSsnapshotdeliveryprogress WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_conflict_MergeProduct_Product]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_conflict_MergeProduct_Product FROM dbo.MSmerge_conflict_MergeProduct_Product WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_articlehistory]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_articlehistory FROM dbo.MSmerge_articlehistory WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSrepl_errors]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSrepl_errors FROM dbo.MSrepl_errors WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_history]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_history FROM dbo.MSmerge_history WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_agent_parameters]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_agent_parameters FROM dbo.MSmerge_agent_parameters WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_replinfo]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_replinfo FROM dbo.MSmerge_replinfo WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysmergearticles]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.sysmergearticles FROM dbo.sysmergearticles WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_conflicts_info]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_conflicts_info FROM dbo.MSmerge_conflicts_info WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_metadataaction_request]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_metadataaction_request FROM dbo.MSmerge_metadataaction_request WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_errorlineage]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_errorlineage FROM dbo.MSmerge_errorlineage WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysmergepublications]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.sysmergepublications FROM dbo.sysmergepublications WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_identity_range]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_identity_range FROM dbo.MSmerge_identity_range WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysmergepartitioninfo]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.sysmergepartitioninfo FROM dbo.sysmergepartitioninfo WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysmergeschemaarticles]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.sysmergeschemaarticles FROM dbo.sysmergeschemaarticles WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_tombstone]') AND type in (N'U'))
BEGIN
--potential high volume table, collect as needed
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_tombstone FROM dbo.MSmerge_tombstone WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_contents]') AND type in (N'U'))
BEGIN
--potential high volume table, collect as needed
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_contents FROM dbo.MSmerge_contents WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_genhistory]') AND type in (N'U'))
BEGIN
--potential high volume table, collect as needed
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_genhistory FROM dbo.MSmerge_genhistory WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_settingshistory]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_settingshistory FROM dbo.MSmerge_settingshistory WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysmergeschemachange]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.sysmergeschemachange FROM dbo.sysmergeschemachange WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysmergesubsetfilters]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.sysmergesubsetfilters FROM dbo.sysmergesubsetfilters WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSdynamicsnapshotviews]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSdynamicsnapshotviews FROM dbo.MSdynamicsnapshotviews WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSdynamicsnapshotjobs]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSdynamicsnapshotjobs FROM dbo.MSdynamicsnapshotjobs WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_altsyncpartners]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_altsyncpartners FROM dbo.MSmerge_altsyncpartners WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_partition_groups]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_partition_groups FROM dbo.MSmerge_partition_groups WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysmergesubscriptions]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.sysmergesubscriptions FROM dbo.sysmergesubscriptions WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_generation_partition_mappings]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_generation_partition_mappings FROM dbo.MSmerge_generation_partition_mappings WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_current_partition_mappings]') AND type in (N'U'))
BEGIN
--potential high volume table, collect as needed
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_current_partition_mappings FROM dbo.MSmerge_current_partition_mappings WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_past_partition_mappings]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_past_partition_mappings FROM dbo.MSmerge_past_partition_mappings WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_sessions]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_sessions FROM dbo.MSmerge_sessions WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_dynamic_snapshots]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_dynamic_snapshots FROM dbo.MSmerge_dynamic_snapshots WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_supportability_settings]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_supportability_settings FROM dbo.MSmerge_supportability_settings WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_log_files]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_log_files FROM dbo.MSmerge_log_files WITH (nolock)
END
Go

--Transactional Replication Tables
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSreplication_subscriptions]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSreplication_subscriptions FROM dbo.MSreplication_subscriptions WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSsubscription_agents]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSsubscription_agents FROM dbo.MSsubscription_agents WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSreplication_objects]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_SubscriberMetadata.dbo.MSreplication_objects FROM dbo.MSreplication_objects WITH (nolock)
END
Go

--Change backup location if needed.
Backup database MS_SubscriberMetadata to disk='c:\MS_SubscriberMetadata.bak'
Go
