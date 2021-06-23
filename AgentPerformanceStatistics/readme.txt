Script to load MSlogreader_history and MSdistribution_history run statistics 
from XML data into table which can be easily queried.
The following statements can help you to extract the performance statistics into a permanent table. There is also a stored procedure that can be used to roughly correlate the Log Reader Agent performance statistics to the Distribution Agent performance statistics. --The perf_stats_tab table.

Original Version of perf_stats_script 
Revised usp_move_stats_to_table.sql 
Revised sp_endtoend_stats.sql
Another Script to read the data realtime or from a distribution database backup 

Notes
• The perf_stats_tab table contains both the Log Reader Agent and the Distribution Agent performance statistics that can be queried independently by using the WHERE TYPE='Distrib' clause or the WHERE TYPE='LogRead' clause. 

• The move_stats_to_tab stored procedure opens a cursor on the mslogreader_history table and on the msdistribution_history table, and then calls the move_stats_to_tab stored procedure for each row to extract the xml performance statistics data into the perf_stats_tab table. 