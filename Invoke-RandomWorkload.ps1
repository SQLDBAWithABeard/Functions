# With thanks to Jonathan Kehayias and Pieter Vanhove

<#
.SYNOPSIS
Runs a random workload against a database using a sql file

.DESCRIPTION
Runs a random workload against a database using PoshRSJobs to create parallel jobs to run random 
queries from a T-SQL file by default it uses the AdventureWorksBOLWorkload.sql from Pieter Vanhove

.PARAMETER SqlInstance
The SQL instance to run the queries against

.PARAMETER SqlCredential
The SQL Credential for the Instance if required

.PARAMETER Database
The name of the database to run the queries against

.PARAMETER NumberOfJobs
The number of jobs to create - default 10

.PARAMETER Delay
The delay in seconds for the output for the running jobs - default 10

.PARAMETER Throttle
The number of parallel jobs to run at a time - default 5

.PARAMETER PathToScript
The path to the T-SQL script holding the queries - default 'C:\temp\AdventureWorksBOLWorkload\AdventureWorksBOLWorkload.sql'

.PARAMETER Delimiter
The delimiter in the T-SQL Script between the queries - default ------

.PARAMETER ShowOutput
Shows the output from the jobs

.EXAMPLE
Invoke-RandomWorkload -SqlInstance $SQL2019CTP23 -SqlCredential $cred -Database AdventureWorks2014 -NumberOfJobs 100 -Delay 10 -Throttle 10 

Runs 100 queries with a maximum of 10 at a time against the AdventureWorks2014 database on $SQL2019CTP23

.EXAMPLE
 $x = 10
 while($X -gt 0){
     Invoke-RandomWorkload -SqlInstance $SQL2019CTP23 -SqlCredential $cred -Database AdventureWorks2014  -NumberOfJobs 1000 -Delay 10 -Throttle 10
 $x --
 }

Runs 1000 queries with a maximum of 10 at a time against the AdventureWorks2014 database on $SQL2019CTP23 10 times in a loop


.NOTES
With thanks to Pieter Vanhove
https://blogs.technet.microsoft.com/msftpietervanhove/2016/01/08/generate-workload-on-your-azure-sql-database/
and
Jonathan Kehayias
https://www.sqlskills.com/blogs/jonathan/the-adventureworks2008r2-books-online-random-workload-generator/
#>

function Invoke-RandomWorkload {
#Requires -Module PoshRsJob
#Requires -Module dbatools
Param(
[string]$SqlInstance,
[pscredential]$SqlCredential,
[string]$Database,
[int]$NumberOfJobs = 10,
[int]$Delay = 10,
[int]$Throttle = 5,
[string]$PathToScript = 'C:\temp\AdventureWorksBOLWorkload\AdventureWorksBOLWorkload.sql',
[string]$Delimiter = "------",
[switch]$ShowOutput
)
    
    #Check if there are old Workload Jobs  
    $WorkloadJobs = Get-RSJob -Name Workload 
    if ($WorkloadJobs) {
        Write-Output "Removing Old WorkLoad Jobs"
        $WorkloadJobs |Stop-RSJob
        $WorkloadJobs | Remove-RSJob
    }
    Write-Output "Creating Background Jobs"     

    1.. $NumberOfJobs | Start-RSJob -Name "WorkLoad"  -Throttle $Throttle -ScriptBlock  {

        # Get the queries
        $Queries = Get-Content -Delimiter $Using:Delimiter -Path $Using:PathToScript 
        # Pick a Random Query from the input object 
        $Query = Get-Random -InputObject $Queries 
        # Run the Query
        # Write-Output "Invoke-DbaQuery -SqlInstance  $Using:SqlInstance -SqlCredential $Using:SqlCredential -Database $Using:Database -Query $Query"
        Invoke-DbaQuery -SqlInstance  $Using:SqlInstance -SqlCredential $Using:SqlCredential -Database $Using:Database -Query $Query 
        # Choose a random number of milliseconds to wait
        $a = Get-Random -Maximum 2000 -Minimum 100; 
        Start-Sleep -Milliseconds $a;     
    } 
 
    $runningJobs = (Get-RSJob -Name WorkLoad -State Running).Count
    While ($runningJobs -ne 0) {
        $jobs = Get-RSJob -Name WorkLoad
        $runningJobs = $Jobs.Where{$PSItem.State -eq 'Running'}.Count
        $WaitingJobs = $Jobs.Where{$PSItem.State -eq 'NotStarted'}.Count
        $CompletedJobs = $Jobs.Where{$PSItem.State -eq 'Completed'}.Count
             
        Write-Output "$runningJobs jobs running - $WaitingJobs jobs waiting - $CompletedJobs -jobs finished"
        Start-Sleep -Seconds $Delay
    }
    Write-Output "Jobs have finished"
    if ($ShowOutput) {
        Write-Output "WorkLoad Jobs Output below -"
        Get-RSJob -Name WorkLoad | Receive-RSJob
    }
    Write-Output "Removing Old WorkLoad Jobs"
    Get-RSJob -Name WorkLoad | Remove-RSJob
    Write-Output "Finished"
}