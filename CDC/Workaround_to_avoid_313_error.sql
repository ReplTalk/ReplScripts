DECLARE @LastReadLSN binary(10)
DECLARE @EndLSN binary(10)
DECLARE @NewStartLSN binary(10)

SET @LastReadLSN = 0x00EA29F80015C3880023
SET @EndLSN   = sys.fn_cdc_get_max_lsn()

IF @LastReadLSN IS NULL -- The first query
BEGIN
  SET @NewStartLSN = sys.fn_cdc_get_min_lsn('dbo_Accounts')
END
ELSE
IF @EndLSN > @LastReadLSN -- Something has happened in the database
BEGIN
  SET @NewStartLSN = sys.fn_cdc_increment_lsn(@LastReadLSN)
END
ELSE
IF @LastReadLSN = @EndLSN -- Nothing has happened in the database
BEGIN
  SET @NewStartLSN = NULL
END

SELECT *
FROM cdc.fn_cdc_get_all_changes_dbo_Accounts (@NewStartLSN, @EndLSN, N'ALL')
WHERE @NewStartLSN IS NOT NULL
