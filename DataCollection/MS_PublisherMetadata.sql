--Publisher Replication Metadata Collection Script
--Execute on the Publisher: modify backup location below as needed
--
--Note: Some errors may appear as not all tables
--     may exists on all subscribers
--

CREATE DATABASE MS_PublisherMetadata
GO

USE <replace with published database name>
GO

--Possible large tables, collect as needed.
--SELECT * INTO MS_PublisherMetadata..MSmerge_contents FROM MSmerge_contents
Go
--SELECT * INTO MS_PublisherMetadata..MSmerge_current_partition_mappings FROM MSmerge_current_partition_mappings
Go
--SELECT * INTO MS_PublisherMetadata..MSmerge_past_partition_mappings FROM MSmerge_past_partition_mappings
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_agent_parameters FROM MSmerge_agent_parameters with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_altsyncpartners FROM MSmerge_altsyncpartners with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_articlehistory FROM MSmerge_articlehistory with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_conflicts_info FROM MSmerge_conflicts_info with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_dynamic_snapshots FROM MSmerge_dynamic_snapshots with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_errorlineage FROM MSmerge_errorlineage with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_generation_partition_mappings FROM MSmerge_generation_partition_mappings with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_genhistory FROM MSmerge_genhistory with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_history FROM MSmerge_history with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_identity_range FROM MSmerge_identity_range with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_log_files FROM MSmerge_log_files with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_metadataaction_request FROM MSmerge_metadataaction_request with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_partition_groups FROM MSmerge_partition_groups with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_replinfo FROM MSmerge_replinfo with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_sessions FROM MSmerge_sessions with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_settingshistory FROM MSmerge_settingshistory with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_supportability_settings FROM MSmerge_supportability_settings with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..MSmerge_tombstone FROM MSmerge_tombstone with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..sysmergearticles FROM sysmergearticles with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..sysmergepartitioninfo FROM sysmergepartitioninfo with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..sysmergepublications FROM sysmergepublications with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..sysmergeschemaarticles FROM sysmergeschemaarticles with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..sysmergeschemachange FROM sysmergeschemachange with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..sysmergesubscriptions FROM sysmergesubscriptions with (nolock)
Go
SELECT * INTO MS_PublisherMetadata..sysmergesubsetfilters FROM sysmergesubsetfilters with (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_conflictdetectionconfigresponse FROM dbo.MSpeer_conflictdetectionconfigresponse WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.sysreplservers FROM dbo.sysreplservers WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.sysarticles FROM dbo.sysarticles WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.sysarticlecolumns FROM dbo.sysarticlecolumns WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.sysschemaarticles FROM dbo.sysschemaarticles WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.syspublications FROM dbo.syspublications WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.syssubscriptions FROM dbo.syssubscriptions WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.sysarticleupdates FROM dbo.sysarticleupdates WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.MSpub_identity_range FROM dbo.MSpub_identity_range WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.systranschemas FROM dbo.systranschemas WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_lsns FROM dbo.MSpeer_lsns WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_request FROM dbo.MSpeer_request WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_response FROM dbo.MSpeer_response WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_topologyrequest FROM dbo.MSpeer_topologyrequest WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_topologyresponse FROM dbo.MSpeer_topologyresponse WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_originatorid_history FROM dbo.MSpeer_originatorid_history WITH (nolock)
Go
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_conflictdetectionconfigrequest FROM dbo.MSpeer_conflictdetectionconfigrequest WITH (nolock)
Go

--Change backup location if needed.
BACKUP DATABASE MS_PublisherMetadata TO DISK='c:\MS_PublisherMetadata.bak'
GO


