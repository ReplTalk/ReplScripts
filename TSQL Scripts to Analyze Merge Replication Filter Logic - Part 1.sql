-- Provided by: Suresh B. Kandoth, SR Escalation Engineer, Microsoft SQL Escalation Services
-- Query to return articles (for each publication) for which there is a filter defined
PRINT '>>Query to return articles (for each publication) for which there is a filter defined'
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
ORDER BY mp.[name], msf.join_filterid
GO

-- Query to return filter definitions on tables which have no index defined
PRINT '>>Query to return filter definitions on tables which have no index defined'
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
WHERE NOT EXISTS 
      (     SELECT idx.index_id FROM sys.indexes idx 
                  WHERE ( (idx.[object_id] = ma.[objid]) AND idx.index_id > 0 )  
      ) 
      OR NOT EXISTS 
      (     SELECT idx.index_id FROM sys.indexes idx 
                  WHERE ( (idx.[object_id] = (SELECT ma1.[objid] FROM sysmergearticles ma1 
                        WHERE ma1.nickname = msf.join_nickname and ma1.pubid = mp.pubid)) AND idx.index_id > 0 ) 
      )
ORDER BY mp.[name], msf.join_filterid
GO
