--Execute on the Subscriber database
--Note: Some errors may appear as not all tables
--     may exists on all subscribers
--

create database MS_SubscriberMetadata
go

Use <replace with subscriber database name>
go

--Merge Replication Tables
SELECT * INTO MS_SubscriberMetadata.dbo.MSsnapshotdeliveryprogress FROM dbo.MSsnapshotdeliveryprogress WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_conflict_MergeProduct_Product FROM dbo.MSmerge_conflict_MergeProduct_Product WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_articlehistory FROM dbo.MSmerge_articlehistory WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSrepl_errors FROM dbo.MSrepl_errors WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_history FROM dbo.MSmerge_history WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_agent_parameters FROM dbo.MSmerge_agent_parameters WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_replinfo FROM dbo.MSmerge_replinfo WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.sysmergearticles FROM dbo.sysmergearticles WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_conflicts_info FROM dbo.MSmerge_conflicts_info WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_metadataaction_request FROM dbo.MSmerge_metadataaction_request WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_errorlineage FROM dbo.MSmerge_errorlineage WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.sysmergepublications FROM dbo.sysmergepublications WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_identity_range FROM dbo.MSmerge_identity_range WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.sysmergepartitioninfo FROM dbo.sysmergepartitioninfo WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.sysmergeschemaarticles FROM dbo.sysmergeschemaarticles WITH (nolock)
Go
--potential high volume table, collect as needed
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_tombstone FROM dbo.MSmerge_tombstone WITH (nolock)
Go
--potential high volume table, collect as needed
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_contents FROM dbo.MSmerge_contents WITH (nolock)
Go
--potential high volume table, collect as needed
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_genhistory FROM dbo.MSmerge_genhistory WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_settingshistory FROM dbo.MSmerge_settingshistory WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.sysmergeschemachange FROM dbo.sysmergeschemachange WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.sysmergesubsetfilters FROM dbo.sysmergesubsetfilters WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSdynamicsnapshotviews FROM dbo.MSdynamicsnapshotviews WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSdynamicsnapshotjobs FROM dbo.MSdynamicsnapshotjobs WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_altsyncpartners FROM dbo.MSmerge_altsyncpartners WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_partition_groups FROM dbo.MSmerge_partition_groups WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.sysmergesubscriptions FROM dbo.sysmergesubscriptions WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_generation_partition_mappings FROM dbo.MSmerge_generation_partition_mappings WITH (nolock)
Go
--potential high volume table, collect as needed
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_current_partition_mappings FROM dbo.MSmerge_current_partition_mappings WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_past_partition_mappings FROM dbo.MSmerge_past_partition_mappings WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_sessions FROM dbo.MSmerge_sessions WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_dynamic_snapshots FROM dbo.MSmerge_dynamic_snapshots WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_supportability_settings FROM dbo.MSmerge_supportability_settings WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSmerge_log_files FROM dbo.MSmerge_log_files WITH (nolock)
Go

--Transactional Replication Tables
SELECT * INTO MS_SubscriberMetadata.dbo.MSreplication_subscriptions FROM dbo.MSreplication_subscriptions WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSsubscription_agents FROM dbo.MSsubscription_agents WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSreplication_objects FROM dbo.MSreplication_objects WITH (nolock)
Go
SELECT * INTO MS_SubscriberMetadata.dbo.MSsnapshotdeliveryprogress FROM dbo.MSsnapshotdeliveryprogress WITH (nolock)
Go

--Change backup location if needed.
Backup database MS_SubscriberMetadata to disk='c:\MS_SubscriberMetadata.bak'
Go

