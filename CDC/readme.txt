Workaround_to_avoid_313_error.sql
Error 313 is expected if LSN range supplied is not appropriate when calling cdc.fn_cdc_get_all_changes_<capture_instance> or cdc.fn_cdc_get_net_changes_<capture_instance>. If the lsn_value parameter is beyond the time of lowest LSN or highest LSN, then execution of these functions will return in error 313: Msg 313, Level 16, State 3, Line 1 An insufficient number of arguments were supplied for the procedure or function. This error should be handled by the developer.

This script is an example to avoid error 313 when the lsn value parameter used in fn_cdc_get_all_changes is beyond the time of highest LSN
