/*
Script to collect Waits for each session
*/

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'SessionWaits')
     DROP EVENT SESSION SessionWaits ON SERVER
 GO

CREATE EVENT SESSION SessionWaits 
ON SERVER 
ADD EVENT sqlos.wait_info( 
       ACTION (sqlserver.session_id) 
    WHERE (
	[package0].[equal_uint64]([sqlserver].[session_id],(180)) ---change to Repl agent session_id\SPID
	--OR [package0].[equal_uint64]([sqlserver].[session_id],(57)) 
	--OR [package0].[equal_uint64]([sqlserver].[session_id],(59)) 
	--OR [package0].[equal_uint64]([sqlserver].[session_id],(61)) 
	--OR [package0].[equal_uint64]([sqlserver].[session_id],(62))
	)
	),
ADD EVENT sqlos.wait_info_external( 
       ACTION (sqlserver.session_id) 
    WHERE 
	([package0].[equal_uint64]([sqlserver].[session_id],(180)) ---change to Repl agent session_id\SPID
	--OR [package0].[equal_uint64]([sqlserver].[session_id],(57)) 
	--OR [package0].[equal_uint64]([sqlserver].[session_id],(59)) 
	--OR [package0].[equal_uint64]([sqlserver].[session_id],(61)) 
	--OR [package0].[equal_uint64]([sqlserver].[session_id],(62))
	)
	)
ADD TARGET package0.asynchronous_file_target 
       (SET FILENAME = N'C:\temp\SessionWaits.xel', 
        METADATAFILE = N'C:\temp\SessionWaits.xem') 
GO 


--Start the Session
ALTER EVENT SESSION SessionWaits 
ON SERVER STATE = START; 


--Stop the Session after about 15 min or after the agents have performed slowly
ALTER EVENT SESSION SessionWaits 
ON SERVER STATE = STOP; 


-- Raw data into intermediate table 
--drop table #ReplicationAgentWaits_Stage_1
SELECT CAST(event_data as XML) event_data 
INTO #ReplicationAgentWaits_Stage_1 
FROM sys.fn_xe_file_target_read_file 
             ('C:\temp\SessionWaits*.xel', 
              'C:\temp\SessionWaits*.xem', 
              NULL, NULL) 


-- Aggregated data into intermediate table 
-- #ReplicationAgentWaits        

SELECT 
       event_data.value 
       ('(/event/action[@name=''session_id'']/value)[1]', 'smallint') as session_id,
       event_data.value 
       ('(/event/data[@name=''wait_type'']/text)[1]', 'varchar(100)') as wait_type,
       event_data.value 
       ('(/event/data[@name=''duration'']/value)[1]', 'bigint') as duration, 
       event_data.value 
       ('(/event/data[@name=''signal_duration'']/value)[1]', 'bigint') as signal_duration,
       event_data.value 
       ('(/event/data[@name=''completed_count'']/value)[1]', 'bigint') as completed_count
INTO #ReplicationAgentWaits_Stage_2 
FROM #ReplicationAgentWaits_Stage_1; 

---then run the below query to see the resault 
SELECT session_id, 
             wait_type, 
             SUM(duration) total_duration_millisec, 
             SUM(signal_duration) total_signal_duration, 
             SUM(completed_count) total_wait_count 
FROM #ReplicationAgentWaits_Stage_2 
GROUP BY session_id, 
             wait_type 
ORDER BY session_id, 
             SUM(duration) DESC; 

