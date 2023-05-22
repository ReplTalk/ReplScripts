--Publisher Replication Metadata Collection Script
--Execute on the Publisher: modify backup location below as needed
--
--

CREATE DATABASE MS_PublisherMetadata
GO

ALTER DATABASE MS_PublisherMetadata SET RECOVERY SIMPLE WITH NO_WAIT;
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
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_agent_parameters]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_agent_parameters FROM MSmerge_agent_parameters with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_altsyncpartners]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_altsyncpartners FROM MSmerge_altsyncpartners with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_articlehistory]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_articlehistory FROM MSmerge_articlehistory with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_conflicts_info]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_conflicts_info FROM MSmerge_conflicts_info with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_dynamic_snapshots]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_dynamic_snapshots FROM MSmerge_dynamic_snapshots with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_errorlineage]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_errorlineage FROM MSmerge_errorlineage with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_generation_partition_mappings]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_generation_partition_mappings FROM MSmerge_generation_partition_mappings with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_genhistory]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_genhistory FROM MSmerge_genhistory with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_history]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_history FROM MSmerge_history with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_identity_range]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_identity_range FROM MSmerge_identity_range with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_log_files]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_log_files FROM MSmerge_log_files with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_metadataaction_request]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_metadataaction_request FROM MSmerge_metadataaction_request with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_partition_groups]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_partition_groups FROM MSmerge_partition_groups with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_replinfo]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_replinfo FROM MSmerge_replinfo with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_sessions]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_sessions FROM MSmerge_sessions with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_settingshistory]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_settingshistory FROM MSmerge_settingshistory with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_supportability_settings]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_supportability_settings FROM MSmerge_supportability_settings with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSmerge_tombstone]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..MSmerge_tombstone FROM MSmerge_tombstone with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysmergearticles]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..sysmergearticles FROM sysmergearticles with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysmergepartitioninfo]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..sysmergepartitioninfo FROM sysmergepartitioninfo with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysmergepublications]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..sysmergepublications FROM sysmergepublications with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysmergeschemaarticles]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..sysmergeschemaarticles FROM sysmergeschemaarticles with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysmergeschemachange]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..sysmergeschemachange FROM sysmergeschemachange with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysmergesubscriptions]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..sysmergesubscriptions FROM sysmergesubscriptions with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysmergesubsetfilters]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata..sysmergesubsetfilters FROM sysmergesubsetfilters with (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSpeer_conflictdetectionconfigresponse]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_conflictdetectionconfigresponse FROM dbo.MSpeer_conflictdetectionconfigresponse WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysreplservers]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.sysreplservers FROM dbo.sysreplservers WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysarticles]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.sysarticles FROM dbo.sysarticles WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysarticlecolumns]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.sysarticlecolumns FROM dbo.sysarticlecolumns WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysschemaarticles]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.sysschemaarticles FROM dbo.sysschemaarticles WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[syspublications]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.syspublications FROM dbo.syspublications WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[syssubscriptions]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.syssubscriptions FROM dbo.syssubscriptions WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysarticleupdates]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.sysarticleupdates FROM dbo.sysarticleupdates WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSpub_identity_range]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.MSpub_identity_range FROM dbo.MSpub_identity_range WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[systranschemas]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.systranschemas FROM dbo.systranschemas WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSpeer_lsns]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_lsns FROM dbo.MSpeer_lsns WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSpeer_request]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_request FROM dbo.MSpeer_request WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSpeer_response]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_response FROM dbo.MSpeer_response WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSpeer_topologyrequest]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_topologyrequest FROM dbo.MSpeer_topologyrequest WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSpeer_topologyresponse]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_topologyresponse FROM dbo.MSpeer_topologyresponse WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSpeer_originatorid_history]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_originatorid_history FROM dbo.MSpeer_originatorid_history WITH (nolock)
END
Go
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSpeer_conflictdetectionconfigrequest]') AND type in (N'U'))
BEGIN
SELECT * INTO MS_PublisherMetadata.dbo.MSpeer_conflictdetectionconfigrequest FROM dbo.MSpeer_conflictdetectionconfigrequest WITH (nolock)
END
Go

--Change backup location if needed.
BACKUP DATABASE MS_PublisherMetadata TO DISK='c:\MS_PublisherMetadata.bak'
GO

