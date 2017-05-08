-- Provided by: Suresh B. Kandoth, SR Escalation Engineer, Microsoft SQL Escalation Services
--Script to explictly check for columns used in the article filter and check existence of indexes on those columns

 
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO
PRINT '>>Script to explictly check for columns used in the article filter and check existence of indexes on those columns'

DECLARE @publication_name sysname, @join_filterid int, @filtername sysname, 
      @article_name sysname, @objid int, @objname sysname, @nickname sysname, 
      @join_article_name sysname, @join_objid int, @join_objname sysname, @join_nickname sysname,
      @join_filterclause nvarchar(1000), @filter_type tinyint, @join_unique_key int;
DECLARE @idxresult XML, @idxresult_char nvarchar(max), @idxrecomm nvarchar(max);
 
DECLARE cursor_filter CURSOR FOR 
      SELECT 
            mp.[name] as "Publication Name" , 
            msf.join_filterid , 
            msf.filtername , 
            ma.[name] as "Article Name" , 
            ma.[objid] as "Object Id" , OBJECT_NAME(objid) as "Object Name",
            ma.nickname , 
            msf.join_articlename  as "Join Article Name", 
            (SELECT ma1.[objid] FROM sysmergearticles ma1 WHERE ma1.nickname = msf.join_nickname and ma1.pubid = mp.pubid) as "Join Object Id", 
            OBJECT_NAME((SELECT ma1.[objid] FROM sysmergearticles ma1 WHERE ma1.nickname = msf.join_nickname and ma1.pubid = mp.pubid)) as "Join Object Name",
            msf.join_nickname,
            msf.join_filterclause, msf.filter_type, msf.join_unique_key  
      FROM sysmergearticles ma
            INNER JOIN sysmergepublications mp ON (ma.pubid = mp.pubid)
                  INNER JOIN sysmergesubsetfilters msf ON (ma.artid = msf.artid)
      ORDER BY mp.[name], msf.join_filterid;
OPEN cursor_filter;
 
FETCH NEXT FROM cursor_filter INTO 
      @publication_name , @join_filterid , @filtername , 
      @article_name , @objid , @objname , @nickname , 
      @join_article_name , @join_objid , @join_objname , @join_nickname ,
      @join_filterclause , @filter_type , @join_unique_key; 
      
WHILE @@FETCH_STATUS = 0
   BEGIN
   PRINT ''
   PRINT 'Filter : ' + @filtername + '    Join clause specified: ' + @join_filterclause
   
   PRINT '        Indexes for Object : '+ @objname;
            SELECT @idxresult = (
            SELECT idx.name as "IndexName" , idx.index_id , idx.type_desc , col.name as "ColumnName" , col.column_id , indcol.key_ordinal , 
                  indcol.is_included_column , indcol.is_descending_key , col.is_merge_published
            FROM sys.indexes idx
                  INNER JOIN sys.index_columns indcol ON ( (idx.[object_id] = indcol.[object_id]) AND (idx.index_id = indcol.index_id))
                        INNER JOIN sys.columns col ON ( (idx.[object_id] = col.[object_id]) AND (indcol.column_id = col.column_id) )
                  WHERE ( idx.[object_id] = @objid ) AND ( idx.index_id > 0 )
                  AND EXISTS ( SELECT indcol1.index_id FROM sys.index_columns indcol1 
                        INNER JOIN sys.columns col1 ON ( (indcol1.column_id = col1.column_id) )
                        WHERE (indcol.index_id = indcol1.index_id) AND (indcol.[object_id] = indcol1.[object_id])
                              AND ( CHARINDEX(col1.name,@join_filterclause,0) > 0 ) 
                              )           
                  ORDER BY idx.index_id
            FOR XML AUTO , ELEMENTS )     
            IF @idxresult IS NULL
                  RAISERROR ( N'                Warning!!! Carefully review the indexes of the table [%s] and filters specified for the article [%s]' , 11 , 1 , 
                        @objname , @article_name)
   
   SET @idxresult_char = REPLACE (CAST(@idxresult AS nvarchar(max)),N'</idx>',N'
                  </idx>
                  ' )
   SET @idxresult_char = REPLACE (@idxresult_char,N'<idx>',N'<idx>
                        ' )               
   SET @idxresult_char = REPLACE (@idxresult_char,N'<col>',N'
                              <col>' )          
   SET @idxresult_char = REPLACE (@idxresult_char,N'</col>',N'
                              </col>' )                                       
   SET @idxresult_char = REPLACE (@idxresult_char,N'<indcol>',N'
                                    <indcol>' )                   
   SET @idxresult_char = REPLACE (@idxresult_char,N'</indcol>',N'
                                    </indcol>' )                                                            
   PRINT '              ' + @idxresult_char;
 
   IF EXISTS (SELECT 1 FROM sys.dm_db_missing_index_details WHERE database_id = DB_ID() AND object_id = @objid)
   BEGIN
      PRINT '                 The following index recommendations were provided by the Missing Index Information DMVs:'
      SELECT @idxrecomm = '                     CREATE INDEX IDX_Missing_Index_' + OBJECT_NAME(@objid) + '_hdl_' + CONVERT(varchar(10),index_handle) + '_' + 
            CONVERT(varchar(10),@join_filterid) + ' ON ' + [statement] + ' (' + [equality_columns] + ' , ' + ISNULL([inequality_columns],'') + ') INCLUDE (' + 
            included_columns + ') '  FROM sys.dm_db_missing_index_details WHERE database_id = DB_ID() AND object_id = @objid
      SET @idxrecomm = REPLACE(@idxrecomm,', )',')')
      SET @idxrecomm = REPLACE(@idxrecomm,'( ,','(')
      SET @idxrecomm = REPLACE(@idxrecomm,'INCLUDE ()',' ')
      PRINT @idxrecomm
      PRINT ''
   END
 
   PRINT '        Indexes for Object : ' + @join_objname;
            SELECT @idxresult = (
            SELECT idx.name as "IndexName" , idx.index_id , idx.type_desc , col.name as "ColumnName" , col.column_id , indcol.key_ordinal , 
                  indcol.is_included_column , indcol.is_descending_key , col.is_merge_published 
            FROM sys.indexes idx
                  INNER JOIN sys.index_columns indcol ON ( (idx.[object_id] = indcol.[object_id]) AND (idx.index_id = indcol.index_id))
                        INNER JOIN sys.columns col ON ( (idx.[object_id] = col.[object_id]) AND (indcol.column_id = col.column_id) )
                  WHERE ( idx.[object_id] = @join_objid ) AND ( idx.index_id > 0 )
                  AND EXISTS ( SELECT indcol1.index_id FROM sys.index_columns indcol1 
                        INNER JOIN sys.columns col1 ON ( (indcol1.column_id = col1.column_id) )
                        WHERE (indcol.index_id = indcol1.index_id) AND (indcol.[object_id] = indcol1.[object_id])
                              AND ( CHARINDEX(col1.name,@join_filterclause,0) > 0 )       
                              )     
                  ORDER BY idx.index_id
            FOR XML AUTO , ELEMENTS )
            IF @idxresult IS NULL
                  RAISERROR ( N'                Warning!!! Carefully review the indexes of the table [%s] and filters specified for the article [%s]' , 11 , 2 , 
                        @join_objname , @article_name)
                              
   SET @idxresult_char = REPLACE (CAST(@idxresult AS nvarchar(max)),N'</idx>',N'
                  </idx>
                  ' )
   SET @idxresult_char = REPLACE (@idxresult_char,N'<idx>',N'<idx>
                        ' )                     
   SET @idxresult_char = REPLACE (@idxresult_char,N'<col>',N'
                              <col>' )          
   SET @idxresult_char = REPLACE (@idxresult_char,N'</col>',N'
                              </col>' )                                       
   SET @idxresult_char = REPLACE (@idxresult_char,N'<indcol>',N'
                                    <indcol>' )                                           
   SET @idxresult_char = REPLACE (@idxresult_char,N'</indcol>',N'
                                    </indcol>' )                                    
   PRINT '              ' + @idxresult_char;
   
   IF EXISTS (SELECT 1 FROM sys.dm_db_missing_index_details WHERE database_id = DB_ID() AND object_id = @join_objid)
   BEGIN
      PRINT '                 The following index recommendations were provided by the Missing Index Information DMVs:'
      SELECT @idxrecomm = '                     CREATE INDEX IDX_Missing_Index_' + OBJECT_NAME(@objid) + '_hdl_' + CONVERT(varchar(10),index_handle) + '_' + 
            CONVERT(varchar(10),@join_filterid) + ' ON ' + [statement] + ' (' + [equality_columns] + ' , ' + ISNULL([inequality_columns],'') + ') INCLUDE (' + 
            included_columns + ') '  FROM sys.dm_db_missing_index_details WHERE database_id = DB_ID() AND object_id = @join_objid
      SET @idxrecomm = REPLACE(@idxrecomm,', )',')')
      SET @idxrecomm = REPLACE(@idxrecomm,'( ,','(')
      SET @idxrecomm = REPLACE(@idxrecomm,'INCLUDE ()',' ') 
      PRINT @idxrecomm
      PRINT ''
   END
   
      FETCH NEXT FROM cursor_filter INTO 
            @publication_name , @join_filterid , @filtername , 
            @article_name , @objid , @objname , @nickname , 
            @join_article_name , @join_objid , @join_objname , @join_nickname ,
            @join_filterclause , @filter_type , @join_unique_key;
   END;
   
CLOSE cursor_filter;
DEALLOCATE cursor_filter;
GO

