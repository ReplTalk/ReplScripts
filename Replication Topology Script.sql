/*
*   *********************************************************************************
*   PURPOSE     :   Getting Replication Topology
*   VERSION     :   1.1
*   RUNS ON     :   The Distributor Server; against the Distribution Database
*   Script written by Suhas De & Gaurav Mathur, Franklin Gamboa Morera, Taiyeb Zakir
*   Copyright Microsoft 
*   *********************************************************************************
*   This script queries the Distribution Database for Replication topology
*   Upgraded to support SQL 2008 and above
*   *********************************************************************************
*/

SET NOCOUNT ON
GO
IF ((SELECT COUNT(*) FROM tempdb.sys.tables WHERE name = '##CE') > 0)
    DROP TABLE ##CE
GO
CREATE TABLE ##CE ([DESCRIPTION] VARCHAR(100) NOT NULL, [VALUE] VARCHAR(100) NOT NULL)
GO
INSERT INTO ##CE VALUES('Continue', 1)
GO
DECLARE @CONSOLEMSG VARCHAR(1000)
DECLARE @SQLVersion VARCHAR(2)
SET @SQLVersion = CONVERT(VARCHAR(2), SERVERPROPERTY('ProductVersion'))
IF SUBSTRING(@SQLVersion, 2, 1) = '.'
    SET @SQLVersion = SUBSTRING(@SQLVersion, 1, 1)
IF CONVERT(INT, @SQLVersion) < 9
    BEGIN
        SET @CONSOLEMSG=CONVERT(VARCHAR(24),GETDATE(),121)+ '   SQL Server connected to is not SQL Server 2005 or SQL Server 2008. Exiting.'
        RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
        UPDATE ##CE SET [VALUE] = 0 WHERE [DESCRIPTION] = 'Continue'
    END
GO
IF ((SELECT [VALUE] FROM ##CE WHERE [DESCRIPTION] = 'Continue') = 1)
    BEGIN
        DECLARE @CONSOLEMSG VARCHAR(1000)
        DECLARE @DistInst VARCHAR(1)
        SELECT @DistInst = CONVERT(VARCHAR(1), ISNULL([is_distributor], 0)) FROM [master].[sys].[servers] (NOLOCK) WHERE [name] = 'repl_distributor' AND [data_source] = CONVERT(SYSNAME, SERVERPROPERTY('ServerName'))
        IF @DistInst IS NULL OR @DistInst = '0'
            BEGIN
                SET @CONSOLEMSG=CONVERT(VARCHAR(24),GETDATE(),121)+ '   Selected instance is not a distributor instance. Exiting.'
                RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
                UPDATE ##CE SET [VALUE] = 0 WHERE [DESCRIPTION] = 'Continue'
            END
        ELSE
            BEGIN
                SET @CONSOLEMSG = REPLACE(CONVERT(VARCHAR(256), SERVERPROPERTY('ServerName')) + ' (DISTRIBUTOR :: ' + CONVERT(VARCHAR(10), SERVERPROPERTY('ProductVersion')) + ')', '.)', ')')
                INSERT INTO ##CE VALUES('Distributor', @CONSOLEMSG)
            END
    END
GO
IF ((SELECT [VALUE] FROM ##CE WHERE [DESCRIPTION] = 'Continue') = 1)
    BEGIN
        DECLARE @CONSOLEMSG VARCHAR(1000)
        SET @CONSOLEMSG = '============================================================='
        RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
        SET @CONSOLEMSG = '                     REPLICATION TOPOLOGY'
        RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
        SET @CONSOLEMSG = '============================================================='
        RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
        SET @CONSOLEMSG = 'SELECT THE PUBLICATION-SUBSCRIPTION PAIR FOR SCOPING THE CASE'
        RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
        SET @CONSOLEMSG = '============================================================='
        RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
        SET @CONSOLEMSG = ' '
        RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
    END
GO
IF ((SELECT [VALUE] FROM ##CE WHERE [DESCRIPTION] = 'Continue') = 1)
    BEGIN
        DECLARE @CONSOLEMSG VARCHAR(1000)
        DECLARE @DISTRIBUTIONDBNAME SYSNAME
        DECLARE @CURRENTDATABASE SYSNAME
        SELECT @DISTRIBUTIONDBNAME = name FROM sys.databases (NOLOCK) WHERE is_distributor = 1
        SELECT @CONSOLEMSG = [VALUE] FROM ##CE WHERE [DESCRIPTION] = 'Distributor'
        SET @CONSOLEMSG = @CONSOLEMSG + ' (Distribution Database: ' + @DISTRIBUTIONDBNAME + ')'
        DELETE ##CE WHERE [DESCRIPTION] = 'Distributor'
        RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
        SELECT @CURRENTDATABASE = DB_NAME()
        IF @CURRENTDATABASE <> @DISTRIBUTIONDBNAME
            BEGIN
                SET @CONSOLEMSG = '   Context Database is not the Distribution Database. Exiting.'
                RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
                UPDATE ##CE SET [VALUE] = 0 WHERE [DESCRIPTION] = 'Continue'
            END
    END
GO
IF ((SELECT [VALUE] FROM ##CE WHERE [DESCRIPTION] = 'Continue') = 1)
    BEGIN
        DECLARE @CONSOLEMSG VARCHAR(1000)
        DECLARE @DISTRIBUTORSERVERNAME SYSNAME
        DECLARE @PUBLISHERNAME SYSNAME
        DECLARE @PUBLISHERID INT
        DECLARE @PUBLISHERNUMBER INT
        DECLARE @PUBLICATIONAME SYSNAME
        DECLARE @PUBLICATIONID INT
        DECLARE @PUBLICATIONTYPE INT
        DECLARE @PUBLICATIONDATABASE SYSNAME
        DECLARE @ALLOW_QUEUED_TRAN INT
        DECLARE @STMT VARCHAR(MAX)
        DECLARE @NUMARTICLES INT
        DECLARE @RESERVEDSIZE BIGINT
        DECLARE @USEDSIZE BIGINT
        DECLARE @INDEXSIZE BIGINT
        DECLARE @SUBSCRIBERNAME SYSNAME
        DECLARE @SUBSCRIPTIONDB SYSNAME
        DECLARE @SUBSCRIPTIONTYPE INT
        
        SET @PUBLISHERNUMBER = 0
        SET @DISTRIBUTORSERVERNAME = CONVERT(SYSNAME, SERVERPROPERTY('ServerName'))
        SET @CONSOLEMSG = '    |- PUBLISHERS'
        RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
        if ((SUBSTRING(convert(varchar(11), SERVERPROPERTY('ProductVersion')), 1, 2) = 13 and SUBSTRING(convert(varchar(11), SERVERPROPERTY('ProductVersion')), 6, 4) >= 5216)
         or (SUBSTRING(convert(varchar(11), SERVERPROPERTY('ProductVersion')), 1, 2) = 14 and SUBSTRING(convert(varchar(11), SERVERPROPERTY('ProductVersion')), 6, 4) >= 3162)
          or (SUBSTRING(convert(varchar(11), SERVERPROPERTY('ProductVersion')), 1, 2) >= 15))
        begin
        --print '1'
            DECLARE PUBLISHERCURSOR CURSOR LOCAL READ_ONLY FOR
            SELECT DISTINCT S.srvname as [NAME], PUB.publisher_id 
              FROM dbo.MSreplservers (NOLOCK) S JOIN dbo.MSpublications (NOLOCK) PUB
                ON S.srvid = PUB.publisher_id
        end 
        else 
        begin
        --print '2'
            DECLARE PUBLISHERCURSOR CURSOR LOCAL READ_ONLY FOR

             SELECT DISTINCT S.name, PUB.publisher_id FROM sys.servers (NOLOCK) S JOIN dbo.MSpublications (NOLOCK) PUB
                 ON S.server_id = PUB.publisher_id
        end

        OPEN PUBLISHERCURSOR

        FETCH NEXT FROM PUBLISHERCURSOR INTO @PUBLISHERNAME, @PUBLISHERID
        WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @PUBLISHERNUMBER = @PUBLISHERNUMBER + 1
                SET @CONSOLEMSG = '        |- ' + @PUBLISHERNAME + ' (Publisher ' + CONVERT(VARCHAR(10), @PUBLISHERNUMBER) + ')'
                RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
                SET @CONSOLEMSG = '            |- PUBLICATIONS'
                RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
                DECLARE PUBLICATIONCURSOR CURSOR LOCAL READ_ONLY FOR
                    SELECT publication, publication_id, publication_type, publisher_db, allow_queued_tran
                    FROM dbo.MSpublications (NOLOCK) WHERE publisher_id = @PUBLISHERID
                OPEN PUBLICATIONCURSOR
                FETCH NEXT FROM PUBLICATIONCURSOR INTO @PUBLICATIONAME, @PUBLICATIONID, 
                    @PUBLICATIONTYPE, @PUBLICATIONDATABASE, @ALLOW_QUEUED_TRAN
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        SET @CONSOLEMSG = '                |- ' + @PUBLICATIONAME + ' ('
                        SET @CONSOLEMSG = @CONSOLEMSG + 'Publication ID: ' + CONVERT(VARCHAR(10), @PUBLICATIONID) + '; '
                        IF @PUBLICATIONTYPE = 0
                            BEGIN
                                IF @ALLOW_QUEUED_TRAN = 0
                                    SET @CONSOLEMSG = @CONSOLEMSG + 'Publication type: Transactional (1-way); '
                                ELSE
                                    SET @CONSOLEMSG = @CONSOLEMSG + 'Publication type: Transactional (2-way); '
                            END
                        ELSE IF @PUBLICATIONTYPE = 1
                            SET @CONSOLEMSG = @CONSOLEMSG + 'Publication type: Snapshot; '
                        ELSE IF @PUBLICATIONTYPE = 2
                            SET @CONSOLEMSG = @CONSOLEMSG + 'Publication type: Merge; '
                        SET @CONSOLEMSG = @CONSOLEMSG + 'Publication database: ' + @PUBLICATIONDATABASE + ')'
                        RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
                        SET @CONSOLEMSG = 'XXX'
                        IF @PUBLICATIONTYPE < 2
                            BEGIN
                                SET @CONSOLEMSG = '                    |- ARTICLES'
                                RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
                                SELECT @NUMARTICLES = COUNT(article_id) FROM MSarticles (NOLOCK) WHERE publication_id = @PUBLICATIONID AND publisher_db = @PUBLICATIONDATABASE
                                SET @CONSOLEMSG = '                        |- ' + CONVERT(VARCHAR(10), @NUMARTICLES) + ' article(s)'
                            END
                        ELSE
                            BEGIN
                                IF @DISTRIBUTORSERVERNAME = @PUBLISHERNAME
                                    BEGIN
                                        SET @CONSOLEMSG = '                    |- ARTICLES'
                                        RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
                                        SET @STMT = 'SET NOCOUNT ON' + CHAR(13)
                                        SET @STMT = @STMT + 'DECLARE @NUMART INT' + CHAR(13)
                                        SET @STMT = @STMT + 'SELECT @NUMART = COUNT(MA.objid) FROM ' + @PUBLICATIONDATABASE + '.dbo.sysmergearticles (NOLOCK) MA JOIN ' + @PUBLICATIONDATABASE + '.dbo.sysmergepublications (NOLOCK) MP ON MA.pubid = MP.pubid WHERE MP.publisher_db = ''' + @PUBLICATIONDATABASE + ''' AND MP.name = ''' + @PUBLICATIONAME + '''' + CHAR(13)
                                        SET @STMT = @STMT + 'INSERT INTO ##CE VALUES (''NUMART'', @NUMART)' + CHAR(13)
                                        EXEC (@STMT)
                                        SELECT @NUMARTICLES = [VALUE] FROM ##CE WHERE [DESCRIPTION] = 'NUMART'
                                        DELETE ##CE WHERE [DESCRIPTION] = 'NUMART'
                                        SET @CONSOLEMSG = '                        |- ' + CONVERT(VARCHAR(10), @NUMARTICLES) + ' article(s)'
                                    END
                            END
                        IF @DISTRIBUTORSERVERNAME = @PUBLISHERNAME
                            BEGIN
                                IF @PUBLICATIONTYPE < 2
                                    BEGIN
                                        SET @STMT = 'SET NOCOUNT ON' + CHAR(13)
                                        SET @STMT = @STMT + 'DECLARE @Reserved BIGINT' + CHAR(13)
                                        SET @STMT = @STMT + 'DECLARE @Used BIGINT' + CHAR(13)
                                        SET @STMT = @STMT + 'DECLARE @Index BIGINT' + CHAR(13)
                                        SET @STMT = @STMT + 'SELECT @Reserved = SUM([Reserved Size (KB)]),' + CHAR(13)
                                        SET @STMT = @STMT + '@Used = SUM([Used Size (KB)]),' + CHAR(13)
                                        SET @STMT = @STMT + '@Index = SUM([Index Size (KB)])' + CHAR(13)
                                        SET @STMT = @STMT + 'FROM (SELECT SUM([PS].[Reserved_Page_Count]) * 8 AS [Reserved Size (KB)],' + CHAR(13)
                                        SET @STMT = @STMT + '   SUM([PS].[Used_Page_Count]) * 8 AS [Used Size (KB)],' + CHAR(13)
                                        SET @STMT = @STMT + '   SUM(' + CHAR(13)
                                        SET @STMT = @STMT + '       CASE' + CHAR(13)
                                        SET @STMT = @STMT + '           WHEN ([PS].[index_id] < 2) THEN ([PS].[in_row_data_page_count] + [PS].[lob_used_page_count] + [PS].[row_overflow_used_page_count])' + CHAR(13)
                                        SET @STMT = @STMT + '           ELSE [PS].[lob_used_page_count] + [PS].[row_overflow_used_page_count]' + CHAR(13)
                                        SET @STMT = @STMT + '       END' + CHAR(13)
                                        SET @STMT = @STMT + '       ) * 8 AS [Index Size (KB)]' + CHAR(13)
                                        SET @STMT = @STMT + 'FROM [msarticles] [MA] (NOLOCK)' + CHAR(13)
                                        SET @STMT = @STMT + 'JOIN ' + @PUBLICATIONDATABASE + '.DBO.[SysArticles] [SA] (NOLOCK)' + CHAR(13)
                                        SET @STMT = @STMT + 'ON [SA].[artid] = [MA].[article_id]' + CHAR(13)
                                        SET @STMT = @STMT + 'JOIN ' + @PUBLICATIONDATABASE + '.[sys].[dm_db_Partition_Stats] [PS] (NOLOCK)' + CHAR(13)
                                        SET @STMT = @STMT + 'ON [PS].[object_id] =  [SA].[objid]' + CHAR(13)
                                        SET @STMT = @STMT + 'WHERE [MA].[publisher_id] = ' + CONVERT(VARCHAR(10), @PUBLISHERID) + CHAR(13)
                                        SET @STMT = @STMT + 'AND [MA].[publication_id] = ' + CONVERT(VARCHAR(10), @PUBLICATIONID) + CHAR(13)
                                        SET @STMT = @STMT + 'GROUP BY [SA].[objid], [MA].[source_owner], [MA].[article]) A' + CHAR(13)
                                        SET @STMT = @STMT + 'INSERT INTO ##CE VALUES (''Reserved'', ISNULL(@Reserved,0))' + CHAR(13)
                                        SET @STMT = @STMT + 'INSERT INTO ##CE VALUES (''Used'', ISNULL(@Used,0))' + CHAR(13)
                                        SET @STMT = @STMT + 'INSERT INTO ##CE VALUES (''Index'', ISNULL(@Index,0))' + CHAR(13)
                                        EXEC (@STMT)
                                        SELECT @RESERVEDSIZE = [VALUE] FROM ##CE WHERE [DESCRIPTION] = 'Reserved'
                                        SELECT @USEDSIZE = [VALUE] FROM ##CE WHERE [DESCRIPTION] = 'Used'
                                        SELECT @INDEXSIZE = [VALUE] FROM ##CE WHERE [DESCRIPTION] = 'Index'
                                        SET @CONSOLEMSG = @CONSOLEMSG + '; Reserved Space = ' + CONVERT(VARCHAR(20), @RESERVEDSIZE) + ' KB, '
                                        SET @CONSOLEMSG = @CONSOLEMSG + 'Used Space = ' + CONVERT(VARCHAR(20), @USEDSIZE) + ' KB, '
                                        SET @CONSOLEMSG = @CONSOLEMSG + 'Index Space = ' + CONVERT(VARCHAR(20), @INDEXSIZE) + ' KB'
                                        DELETE ##CE WHERE [DESCRIPTION] IN ('Reserved', 'Used', 'Index')
                                    END
                                ELSE
                                    BEGIN
                                        SET @STMT = 'SET NOCOUNT ON' + CHAR(13)
                                        SET @STMT = @STMT + 'DECLARE @Reserved BIGINT' + CHAR(13)
                                        SET @STMT = @STMT + 'DECLARE @Used BIGINT' + CHAR(13)
                                        SET @STMT = @STMT + 'DECLARE @Index BIGINT' + CHAR(13)
                                        SET @STMT = @STMT + 'SELECT @Reserved = SUM([Reserved Size (KB)]),' + CHAR(13)
                                        SET @STMT = @STMT + '@Used = SUM([Used Size (KB)]),' + CHAR(13)
                                        SET @STMT = @STMT + '@Index = SUM([Index Size (KB)])' + CHAR(13)
                                        SET @STMT = @STMT + 'FROM (SELECT SUM([PS].[Reserved_Page_Count]) * 8 AS [Reserved Size (KB)],' + CHAR(13)
                                        SET @STMT = @STMT + '   SUM([PS].[Used_Page_Count]) * 8 AS [Used Size (KB)],' + CHAR(13)
                                        SET @STMT = @STMT + '   SUM(' + CHAR(13)
                                        SET @STMT = @STMT + '       CASE' + CHAR(13)
                                        SET @STMT = @STMT + '           WHEN ([PS].[index_id] < 2) THEN ([PS].[in_row_data_page_count] + [PS].[lob_used_page_count] + [PS].[row_overflow_used_page_count])' + CHAR(13)
                                        SET @STMT = @STMT + '           ELSE [PS].[lob_used_page_count] + [PS].[row_overflow_used_page_count]' + CHAR(13)
                                        SET @STMT = @STMT + '       END' + CHAR(13)
                                        SET @STMT = @STMT + '       ) * 8 AS [Index Size (KB)]' + CHAR(13)
                                        SET @STMT = @STMT + 'FROM ' + @PUBLICATIONDATABASE + '.dbo.sysmergearticles MA (NOLOCK) JOIN ' + @PUBLICATIONDATABASE + '.dbo.sysmergepublications (NOLOCK) MP ON MA.PUBID = MP.PUBID' + CHAR(13)
                                        SET @STMT = @STMT + 'JOIN ' + @PUBLICATIONDATABASE + '.[sys].[dm_db_Partition_Stats] [PS] (NOLOCK) ON [PS].[object_id] = [MA].[OBJID]' + CHAR(13)
                                        SET @STMT = @STMT + 'WHERE MP.publisher_db = ''' + @PUBLICATIONDATABASE + ''' AND MP.NAME = ''' + @PUBLICATIONAME + ''') A' + CHAR(13)
                                        SET @STMT = @STMT + 'INSERT INTO ##CE VALUES (''Reserved'', ISNULL(@Reserved,0))' + CHAR(13)
                                        SET @STMT = @STMT + 'INSERT INTO ##CE VALUES (''Used'', ISNULL(@Used,0))' + CHAR(13)
                                        SET @STMT = @STMT + 'INSERT INTO ##CE VALUES (''Index'', ISNULL(@Index,0))' + CHAR(13)
                                        EXEC (@STMT)
                                        SELECT @RESERVEDSIZE = [VALUE] FROM ##CE WHERE [DESCRIPTION] = 'Reserved'
                                        SELECT @USEDSIZE = [VALUE] FROM ##CE WHERE [DESCRIPTION] = 'Used'
                                        SELECT @INDEXSIZE = [VALUE] FROM ##CE WHERE [DESCRIPTION] = 'Index'
                                        SET @CONSOLEMSG = @CONSOLEMSG + '; Reserved Space = ' + CONVERT(VARCHAR(20), @RESERVEDSIZE) + ' KB, '
                                        SET @CONSOLEMSG = @CONSOLEMSG + 'Used Space = ' + CONVERT(VARCHAR(20), @USEDSIZE) + ' KB, '
                                        SET @CONSOLEMSG = @CONSOLEMSG + 'Index Space = ' + CONVERT(VARCHAR(20), @INDEXSIZE) + ' KB'
                                        DELETE ##CE WHERE [DESCRIPTION] IN ('Reserved', 'Used', 'Index')
                                    END
                            END
                        IF @CONSOLEMSG <> 'XXX'
                            RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
                        SET @CONSOLEMSG = '                    |- SUBSCRIPTIONS'
                        RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
                        IF @PUBLICATIONTYPE < 2
                            BEGIN
                                --Subscriber
                                    if ((SUBSTRING(convert(varchar(11), SERVERPROPERTY('ProductVersion')), 1, 2) = 13 and SUBSTRING(convert(varchar(11), SERVERPROPERTY('ProductVersion')), 6, 4) >= 5216)
                                     or (SUBSTRING(convert(varchar(11), SERVERPROPERTY('ProductVersion')), 1, 2) = 14 and SUBSTRING(convert(varchar(11), SERVERPROPERTY('ProductVersion')), 6, 4) >= 3162)
                                      or (SUBSTRING(convert(varchar(11), SERVERPROPERTY('ProductVersion')), 1, 2) >= 15))
                                    begin
                                        DECLARE SUBSCRIPTIONCURSOR CURSOR LOCAL READ_ONLY FOR
                                        SELECT DISTINCT S.srvname as [NAME], SUB.subscriber_db, SUB.subscription_type
                                          FROM dbo.MSreplservers (NOLOCK) S JOIN MSsubscriptions SUB (NOLOCK) ON S.srvid = SUB.subscriber_id
                                        WHERE SUB.publication_id = @PUBLICATIONID AND SUB.publisher_db = @PUBLICATIONDATABASE AND SUB.subscriber_id >= 0
        

                                    end 
                                    else 
                                    begin
                                        DECLARE SUBSCRIPTIONCURSOR CURSOR LOCAL READ_ONLY FOR
                                        SELECT DISTINCT S.name, SUB.subscriber_db, SUB.subscription_type
                                        FROM sys.servers S (NOLOCK) JOIN MSsubscriptions SUB (NOLOCK) ON S.server_id = SUB.subscriber_id
                                        WHERE SUB.publication_id = @PUBLICATIONID AND SUB.publisher_db = @PUBLICATIONDATABASE AND SUB.subscriber_id >= 0
                                    end
                                OPEN SUBSCRIPTIONCURSOR
                                FETCH NEXT FROM SUBSCRIPTIONCURSOR INTO @SUBSCRIBERNAME, @SUBSCRIPTIONDB, @SUBSCRIPTIONTYPE
                                WHILE @@FETCH_STATUS = 0
                                    BEGIN
                                        SET @CONSOLEMSG = '                        |- ' + @SUBSCRIBERNAME + ' ('
                                        SET @CONSOLEMSG = @CONSOLEMSG + 'Subscription Database: ' + @SUBSCRIPTIONDB + '; '
                                        IF @SUBSCRIPTIONTYPE = 0
                                            SET @CONSOLEMSG = @CONSOLEMSG + 'Subscription Type: Push)'
                                        ELSE IF @SUBSCRIPTIONTYPE = 1
                                            SET @CONSOLEMSG = @CONSOLEMSG + 'Subscription Type: Pull)'
                                        RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
                                        FETCH NEXT FROM SUBSCRIPTIONCURSOR INTO @SUBSCRIBERNAME, @SUBSCRIPTIONDB, @SUBSCRIPTIONTYPE
                                    END
                                CLOSE SUBSCRIPTIONCURSOR
                                DEALLOCATE SUBSCRIPTIONCURSOR
                            END
                        ELSE
                            BEGIN
                                DECLARE SUBSCRIPTIONCURSOR CURSOR LOCAL READ_ONLY FOR
                                    SELECT subscriber, subscriber_db, subscription_type
                                    FROM MSmerge_subscriptions (NOLOCK) WHERE publication_id = @PUBLICATIONID AND publisher_db = @PUBLICATIONDATABASE
                                OPEN SUBSCRIPTIONCURSOR
                                FETCH NEXT FROM SUBSCRIPTIONCURSOR INTO @SUBSCRIBERNAME, @SUBSCRIPTIONDB, @SUBSCRIPTIONTYPE
                                WHILE @@FETCH_STATUS = 0
                                    BEGIN
                                        SET @CONSOLEMSG = '                        |- ' + @SUBSCRIBERNAME + ' ('
                                        SET @CONSOLEMSG = @CONSOLEMSG + 'Subscription Database: ' + @SUBSCRIPTIONDB + '; '
                                        IF @SUBSCRIPTIONTYPE = 0
                                            SET @CONSOLEMSG = @CONSOLEMSG + 'Subscription Type: Push)'
                                        ELSE IF @SUBSCRIPTIONTYPE = 1
                                            SET @CONSOLEMSG = @CONSOLEMSG + 'Subscription Type: Pull)'
                                        RAISERROR (@CONSOLEMSG,10,1) WITH NOWAIT
                                        FETCH NEXT FROM SUBSCRIPTIONCURSOR INTO @SUBSCRIBERNAME, @SUBSCRIPTIONDB, @SUBSCRIPTIONTYPE
                                    END
                                CLOSE SUBSCRIPTIONCURSOR
                                DEALLOCATE SUBSCRIPTIONCURSOR
                            END
                        FETCH NEXT FROM PUBLICATIONCURSOR INTO @PUBLICATIONAME, @PUBLICATIONID, 
                            @PUBLICATIONTYPE, @PUBLICATIONDATABASE, @ALLOW_QUEUED_TRAN
                    END
                CLOSE PUBLICATIONCURSOR
                DEALLOCATE PUBLICATIONCURSOR
                
                FETCH NEXT FROM PUBLISHERCURSOR INTO @PUBLISHERNAME, @PUBLISHERID
            END
        CLOSE PUBLISHERCURSOR
        DEALLOCATE PUBLISHERCURSOR
        
    END
GO
DROP TABLE ##CE
GO