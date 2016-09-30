# You will need to add the path to Test-Ola.ps1 on Line 90

function Test-OLAInstance
{
<#
.Synopsis 
   This function will run a Pester Test for backup solution using OLA Hallengrens maintenance solution
.DESCRIPTION 
   Tests an instance or a number of instances to ensure that the OLA Hallengren solution is set up correctly. That 
   all agent jobs exist, are schedeuled and were successful
   That the relevant folders for each database exist and that there are backups files in the folders
   It uses the Test-Ola.ps1 file You will need to add the path to Test-Ola.ps1 on Line 90
.EXAMPLE
   Test-OLAInstance -Instance 'Server1' -Share '\\UNCPath'

   This will check that the SQL Agent is running on Server1, That there are Ola Hallengren maintenance solution agent jobs on Server1. That the
   jobs are enabled and have a schedule. It also checks for the Server1 folder in the share and the existence of the Database Restore Text File
.EXAMPLE
   Test-OLAInstance -Instance 'Server1'  -Share '\\UNCPath' -CheckForDBFolders

   This will check that the SQL Agent is running on Server1, That there are Ola Hallengren maintenance solution agent jobs on Server1. That the
   jobs are enabled and have a schedule. It also checks for the Server1 folder in the share and the existence of the Database Restore Text File
   It checks that for each database the required FULL,DIFF or LOG folders exist
.EXAMPLE 
   Test-OLAInstance -Instance Server1 -Share '\\UNCPath' -CheckForDBFolders -CheckForBackups

   This will check that the SQL Agent is running on Server1, That there are Ola Hallengren maintenance solution agent jobs on Server1. That the
   jobs are enabled and have a schedule. It also checks for the Server1 folder in the share and the existence of the Database Restore Text File
   It checks that for each database the required FULL,DIFF or LOG folders exist and that they have a .bak or a .trn file in them
.EXAMPLE
   Test-OLAInstance -Instance Server1 -Share '\\UNCPath' -CheckForDBFolders -CheckForBackups -JobSuffix 'TheBeard'

   This will check that the SQL Agent is running on Server1, That there are Ola Hallengren maintenance solution agent jobs on Server1 with a Job
   Suffix of TheBeard. That the jobs are enabled and have a schedule. It also checks for the Server1 folder in the share and the existence of the 
   Database Restore Text File. It checks that for each database the required FULL,DIFF or LOG folders exist and that they have a .bak or a .trn file in them
.EXAMPLE 
    Test-OLAInstance -Instance 'Server1','Server2','Server3' -Share '\\UNCPath' -DontCheckJobOutcome 
   
   This will check that the SQL Agent is running on Server1,Server2 and Server3, That there are Ola Hallengren maintenance solution agent jobs on Server1,Server2 and Server3. That the
   jobs are enabled and have a schedule. It also checks for the Server1,Server2 and Server3 folders in the share and the existence of the Database Restore Text File
.EXAMPLE 
    $Servers = (Invoke-Sqlcmd -ServerInstance dbareports -Database dbareports -Query "Select Servername from dbo.InstanceList where Environment = 'Development' and Inactive = 0 and NotContactable = 0").ServerName
    Test-OLAInstance -Instance $Servers
   
   This will check that the SQL Agent is running on the servers returned from a query against the dbareports, That there are Ola Hallengren maintenance solution agent jobs on Server1,Server2 and Server3. That the
   jobs are enabled and have a schedule but not that they succeeeded. It also checks for the Server1,Server2 and Server3 folders in the share and the existence of the Database Restore Text File
.EXAMPLE 
    $Servers = (Invoke-Sqlcmd -ServerInstance dbareports -Database dbareports -Query "Select Servername from dbo.InstanceList where Environment = 'Development' and Inactive = 0 and NotContactable = 0").ServerName
    Test-OLAInstance -Instance $Servers -Report
   
   This will check that the SQL Agent is running on the servers returned from a query against the dbareports, That there are Ola Hallengren maintenance solution agent jobs on Server1,Server2 and Server3. That the
   jobs are enabled and have a schedule but not that they succeeeded. It also checks for the Server1,Server2 and Server3 folders in the share and the existence of the Database Restore Text File
   It will also download the ReportUnit Exe if it doesnt exist and create an HTML Report

.NOTES
   AUTHOR - Rob Sewell https://sqldbawithabeard.com @SQLDBAWithBeard
   DATE - 07/09/2016
#>
#requires -Version 5
#Requires -Modules Pester
#Requires -Modules sqlserver
[CmdletBinding()]

Param(
        # The instance or an array of instances that you wish to test
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [object]$Instance,
        # A switch to add tests for existence of file in the backup folders - will be slower
        [Parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]$CheckForBackups,
        # A switch to add tests for existence of database backup folders - will be slower - Not needed if you Check for Backups
        [Parameter(Mandatory=$false)]
        [switch]$CheckForDBFolders,
        # The Job Suffix for the OLA backup jobs
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$JobSuffix,
        # The name of the OLA backup share 
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Share,
        # A switch to not perform the test for the existence of a database restore text file created using proc Created by Jared Zagelbaum, https://jaredzagelbaum.wordpress.com/
        [Parameter(Mandatory=$false)]
        [switch]$NoDatabaseRestoreCheck,
        # A switch to not perform the test if the Job succeeded
        [Parameter(Mandatory=$false)]
        [switch]$DontCheckJobOutcome ,
        # A switch to output a report HTML
        [Parameter(Mandatory=$false)]
        [switch]$Report 
)


$Path = 'Git:\Functions\Test-OLA.ps1'
$Script = @{
Path = $Path;
Parameters = @{ Instance = $Instance;
CheckForBackups =  $CheckForBackups;
CheckForDBFolders =  $CheckForDBFolders;
JobSuffix = $JobSuffix; 
Share = $Share;
NoDatabaseRestoreCheck = $NoDatabaseRestoreCheck;
DontCheckJobOutcome  = $DontCheckJobOutcome }
}
if($Report)
{
$Date = Get-Date -Format ddMMyyyHHmmss
$File = $tempFolder + '\Script_Pester_Report_' + $date
$XML = $File + '.xml'
$HTML = $file + '.html'
Invoke-Pester -Script $Script -OutputFile $xml -OutputFormat NUnitXml
$tempFolder = 'c:\temp'
Push-Location $tempFolder
#download and extract ReportUnit.exe
$url = 'http://relevantcodes.com/Tools/ReportUnit/reportunit-1.2.zip'
$fullPath = Join-Path $tempFolder $url.Split("/")[-1]
$reportunit = $tempFolder + '\reportunit.exe'
if((Test-Path $reportunit) -eq $false)
{
(New-Object Net.WebClient).DownloadFile($url,$fullPath)
Expand-Archive -Path $fullPath -DestinationPath $tempFolder
}
#run reportunit against report.xml and display result in browser
& .\reportunit.exe $XML
ii $HTML
}
else
{
Invoke-Pester -Script $Script
}
}
