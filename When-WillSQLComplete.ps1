<#
    .Synopsis
    A quick function to estimate the completion time of a SQL Statement
    .DESCRIPTION
    Runs some t-sql to gather osme information about requests from the sys.dm_exec_requests dmv to estimate the 
    amount of time remaining for a statement which can be filtered by BACKUP,RESTORE,INDEX,DBCC,STATS commands
    .EXAMPLE
    When-WillThisSQLComplete -Server Fade2black

    Returns SPID, Login Name,Domain, NTUserName,Database, %,START_TIME,STATUS,COMMAND,EST_COMP for all processes on Fade2Black
    .EXAMPLE
    When-WillThisSQLComplete -Server SQLServer1 -Commandtype Backup

    Returns SPID, Login Name,Domain, NTUserName,Database, %,START_TIME,STATUS,COMMAND,EST_COMP for all processes on SQLServer1

    .NOTES
    AUTHOR : Rob Sewell http://sqldbawithabeard.com

#>
function When-WillSQLComplete
{
param([string]$Server,
[ValidateSet("Backup", "Restore", "Index","DBCC","Stats")]
[string]$Commandtype
)
$BaseQuery = @"
USE MASTER
GO
SELECT
	DER.SESSION_ID as SPID,
	RTRIM(SP.Loginame) as 'Login Name',
	RTRIM(SP.nt_domain) as Domain,
	RTRIM(SP.nt_username) as NTUserName,
	'[' + CAST(DER.DATABASE_ID AS VARCHAR(10)) + '] ' + DB_NAME(DER.DATABASE_ID) AS [Database],
	DER.PERCENT_COMPLETE as '%', DER.START_TIME, DER.STATUS, DER.COMMAND,
	DATEADD(MS, DER.ESTIMATED_COMPLETION_TIME, GETDATE()) AS EST_COMP,
	DER.CPU_TIME
FROM SYS.DM_EXEC_REQUESTS DER
left join
sys.sysprocesses SP
on DER.Session_id = SP.spid
--Apply this Where Clause Filter if you need to check specific events
--such as Backups, Restores, Index et al.

"@
$BackupCMD = @"
WHERE COMMAND LIKE '%BACKUP%'
"@
$RestoreCMD = @"
WHERE COMMAND LIKE '%RESTORE%' 
"@
$IndexCMD = @"
WHERE COMMAND LIKE '%INDEX%'
"@
$DBCCCMD = @"
WHERE COMMAND LIKE '%DBCC%'
"@
$StatsCMD = @"
WHERE COMMAND LIKE 'UPDATE STAT%'
"@
switch ($Commandtype)
{
Backup   {$query = $BaseQuery + $BackupCMD }
Restore  {$query = $BaseQuery + $RestoreCMD}
Index    {$query = $BaseQuery + $IndexCMD}
DBCC     {$query = $BaseQuery + $DBCCCMD}
Stats    {$query = $BaseQuery + $StatsCMD}
default  {$query = $BaseQuery }
}
Invoke-Sqlcmd -ServerInstance $Server -Database master -Query $query|ft
}