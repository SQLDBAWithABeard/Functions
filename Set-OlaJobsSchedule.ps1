#requires -Version 1
<# 
    .SYNOPSIS  
    Script to set some default schedules for the default jobs created by Ola Hallengrens Maintenance Solution

    .DESCRIPTION 
    This script will set some default job schedules for Ola Hallengrens Maintenance Solution default Jobs
    following the guidance on his website

    Follow these guidelines from Ola's website https://ola.hallengren.com 

    The "One Day a week here should be a different day of the week

    User databases:
    â€¢Full backup one day per week   Sunday 00:16                               * If using differentials otherwise daily
    â€¢Differential backup all other days of the week   00:16             * If required - otherwise don't schedule
    â€¢Transaction log backup every hour
    â€¢Integrity check one day per week 20:16 on a Friday
    â€¢Index maintenance one day per week

    System databases:
    â€¢Full backup every day 23:46
    â€¢Integrity check one day per week 23:16 on a Friday

    I recommend that you run a full backup after the index maintenance. The following differential backups will then be small. I also recommend that you perform the full backup after the integrity check. Then you know that the integrity of the backup is okay.


    The one day of a week here can be the same day of the week

    Cleanup:
    â€¢sp_delete_backuphistory one day per week 19:16 on a Sunday
    â€¢sp_purge_jobhistory one day per week 19:16 on a Sunday
    â€¢CommandLog cleanup one day per week 19:16 on a Sunday
    â€¢Output file cleanup one day per week 19:16 on a Sunday

    .PARAMETER 
    Server
    This is the connection string required to connect to the SQL Instance ServerName for a default instance, Servername\InstanceName or ServerName\InstanceName,Port
    .EXAMPLE 
    Schedule-OlaJobs ServerName\InstanceName


    .NOTES 
    Obviously requires Ola Hallengrens Maintnance Solution script to have been run first and only schedules the default jobs
    https://ola.hallengren.com/
    AUTHOR: Rob Sewell sqldbawithabeard.com 
    DATE: 1/05/2015 - Initial
#> 

function Set-OlaJobsSchedule
{
  param([string]$Server)
  #Connect to server
        
  $srv = New-Object -TypeName Microsoft.SQLServer.Management.SMO.Server -ArgumentList $Server
  $JobServer = $srv.JobServer
  $Jobs = $JobServer.Jobs

  # Set Schedule for Full System DBs to once a day just before midnight

  $Job = $Jobs|Where-Object -FilterScript {
    $_.Name -eq 'DatabaseBackup - SYSTEM_DATABASES - FULL'
  }
  if ($Null -eq $Job) 
  {
    Write-Output -InputObject 'No Job with that name' 
    break
  }
  else
  {
    $Schedule = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.JobSchedule -ArgumentList ($Job, 'Daily - Midnight --')
    $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
    $Schedule.ActiveEndTimeOfDay = '23:59:59'
    $Schedule.FrequencyTypes = 'Daily'  
    $Schedule.FrequencySubDayTypes = 'Once'  
    $Schedule.FrequencyInterval = 1  
    $Schedule.ActiveStartDate = Get-Date  
    $Schedule.ActiveStartTimeOfDay = '23:46:00'
    $Schedule.IsEnabled = $true
    $Schedule.Create()  
  }
  # Set Schedule for Full User DBs to once a week just after midnight on Sunday

  $Job = $Jobs|Where-Object -FilterScript {
    $_.Name -eq 'DatabaseBackup - USER_DATABASES - FULL'
  }
  if ($Null -eq $Job) 
  {
    Write-Output -InputObject 'No Job with that name' 
    break
  }
  else
  {
    $Schedule = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.JobSchedule -ArgumentList ($Job, 'Weekly Sunday - Midnight ++')
    $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
    $Schedule.ActiveEndTimeOfDay = '23:59:59'
    $Schedule.FrequencyTypes = 'Weekly' 
    $Schedule.FrequencyRecurrenceFactor = 1 
    $Schedule.FrequencyInterval = 1  
    $Schedule.ActiveStartDate = Get-Date  
    $Schedule.ActiveStartTimeOfDay = '00:16:00'
    $Schedule.IsEnabled = $true
    $Schedule.Create()  
  }
  # Set Schedule for Diff User DBs to once a day just after midnight

  $Job = $Jobs|Where-Object -FilterScript {
    $_.Name -eq 'DatabaseBackup - USER_DATABASES - DIFF'
  }
  if ($Null -eq $Job) 
  {
    Write-Output -InputObject 'No Job with that name' 
    break
  }
  else
  {
    $Schedule = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.JobSchedule -ArgumentList ($Job, 'Daily - Midnight ++ Not Sunday')
    $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
    $Schedule.ActiveEndTimeOfDay = '23:59:59'
    $Schedule.FrequencyTypes = 'Weekly'  
    $Schedule.FrequencyRecurrenceFactor = 1
    $Schedule.FrequencySubDayTypes = 'Once'  
    $Schedule.FrequencyInterval = 126 # Weekdays 62 + Saturdays 64  - https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.agent.jobschedule.frequencyinterval.aspx
    $Schedule.ActiveStartDate = Get-Date  
    $Schedule.ActiveStartTimeOfDay = '00:16:00'
    $Schedule.IsEnabled = $true
    $Schedule.Create()  
  }
  # Set Schedule for Full System DBs to once a day just before midnight

  $Job = $Jobs|Where-Object -FilterScript {
    $_.Name -eq 'DatabaseBackup - USER_DATABASES - LOG'
  }
  if ($Null -eq $Job) 
  {
    Write-Output -InputObject 'No Job with that name' 
    break
  }
  else
  {
    $Schedule = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.JobSchedule -ArgumentList ($Job, 'Hourly between 7 and 3')
    $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
    $Schedule.ActiveEndTimeOfDay = '02:59:59'
    $Schedule.FrequencyTypes = 'Daily'  
    $Schedule.FrequencySubDayTypes = 'Hour' 
    $Schedule.FrequencySubDayInterval = 1 
    $Schedule.FrequencyInterval = 1  
    $Schedule.ActiveStartDate = Get-Date  
    $Schedule.ActiveStartTimeOfDay = '06:46:00'
    $Schedule.IsEnabled = $true
    $Schedule.Create()  
  }

  # Set Schedule for System DBCC to once a week just before midnight on Friday

  $Job = $Jobs|Where-Object -FilterScript {
    $_.Name -eq 'DatabaseIntegrityCheck - SYSTEM_DATABASES'
  }
  if ($Null -eq $Job) 
  {
    Write-Output -InputObject 'No Job with that name' 
    break
  }
  else
  {
    $Schedule = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.JobSchedule -ArgumentList ($Job, 'Weekly Friday - Midnight --')
    $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
    $Schedule.ActiveEndTimeOfDay = '23:59:59'
    $Schedule.FrequencyTypes = 'Weekly' 
    $Schedule.FrequencyRecurrenceFactor = 1 
    $Schedule.FrequencyInterval = 64 
    $Schedule.ActiveStartDate = Get-Date  
    $Schedule.ActiveStartTimeOfDay = '23:16:00'
    $Schedule.IsEnabled = $true
    $Schedule.Create()  
  }
  # Set Schedule for User DBCC to once a week on Saturday Evening

  $Job = $Jobs|Where-Object -FilterScript {
    $_.Name -eq 'DatabaseIntegrityCheck - USER_DATABASES'
  }
  if ($Null -eq $Job) 
  {
    Write-Output -InputObject 'No Job with that name' 
    break
  }
  else
  {
    $Schedule = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.JobSchedule -ArgumentList ($Job, 'Weekly Saturday - Evening')
    $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
    $Schedule.ActiveEndTimeOfDay = '23:59:59'
    $Schedule.FrequencyTypes = 'Weekly' 
    $Schedule.FrequencyRecurrenceFactor = 1 
    $Schedule.FrequencyInterval = 64 
    $Schedule.ActiveStartDate = Get-Date  
    $Schedule.ActiveStartTimeOfDay = '20:16:00'
    $Schedule.IsEnabled = $true
    $Schedule.Create()  
  }
  # Set Schedule for User IndexOptimize to once a week on Saturday Morning

  $Job = $Jobs|Where-Object -FilterScript {
    $_.Name -eq 'IndexOptimize - USER_DATABASES'
  }
  if ($Null -eq $Job) 
  {
    Write-Output -InputObject 'No Job with that name' 
    break
  }
  else
  {
    $Schedule = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.JobSchedule -ArgumentList ($Job, 'Weekly Saturday - AM')
    $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
    $Schedule.ActiveEndTimeOfDay = '23:59:59'
    $Schedule.FrequencyTypes = 'Weekly' 
    $Schedule.FrequencyRecurrenceFactor = 1 
    $Schedule.FrequencyInterval = 64 
    $Schedule.ActiveStartDate = Get-Date  
    $Schedule.ActiveStartTimeOfDay = '01:16:00'
    $Schedule.IsEnabled = $true
    $Schedule.Create()  
  }
  # Set Schedule for CommandLog Cleanup to once a week on Sunday Evening

  $Job = $Jobs|Where-Object -FilterScript {
    $_.Name -eq 'CommandLog Cleanup'
  }
  if ($Null -eq $Job) 
  {
    Write-Output -InputObject 'No Job with that name' 
    break
  }
  else
  {
    $Schedule = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.JobSchedule -ArgumentList ($Job, 'Weekly Sunday - Evening ')
    $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
    $Schedule.ActiveEndTimeOfDay = '23:59:59'
    $Schedule.FrequencyTypes = 'Weekly' 
    $Schedule.FrequencyRecurrenceFactor = 1 
    $Schedule.FrequencyInterval = 1 
    $Schedule.ActiveStartDate = Get-Date  
    $Schedule.ActiveStartTimeOfDay = '19:16:00'
    $Schedule.IsEnabled = $true
    $Schedule.Create()  
  }
  # Set Schedule for Output File Cleanup to once a week on Sunday Evening

  $Job = $Jobs|Where-Object -FilterScript {
    $_.Name -eq 'Output File Cleanup'
  }
  if ($Null -eq $Job) 
  {
    Write-Output -InputObject 'No Job with that name' 
    break
  }
  else
  {
    $Schedule = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.JobSchedule -ArgumentList ($Job, 'Weekly Sunday - Evening ')
    $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
    $Schedule.ActiveEndTimeOfDay = '23:59:59'
    $Schedule.FrequencyTypes = 'Weekly' 
    $Schedule.FrequencyRecurrenceFactor = 1 
    $Schedule.FrequencyInterval = 1 
    $Schedule.ActiveStartDate = Get-Date  
    $Schedule.ActiveStartTimeOfDay = '19:16:00'
    $Schedule.IsEnabled = $true
    $Schedule.Create()  
  }
  # Set Schedule for sp_delete_backuphistory to once a week on Sunday Evening

  $Job = $Jobs|Where-Object -FilterScript {
    $_.Name -eq 'sp_delete_backuphistory'
  }
  if ($Null -eq $Job) 
  {
    Write-Output -InputObject 'No Job with that name' 
    break
  }
  else
  {
    $Schedule = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.JobSchedule -ArgumentList ($Job, 'Weekly Sunday - Evening ')
    $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
    $Schedule.ActiveEndTimeOfDay = '23:59:59'
    $Schedule.FrequencyTypes = 'Weekly' 
    $Schedule.FrequencyRecurrenceFactor = 1 
    $Schedule.FrequencyInterval = 1 
    $Schedule.ActiveStartDate = Get-Date  
    $Schedule.ActiveStartTimeOfDay = '19:16:00'
    $Schedule.IsEnabled = $true
    $Schedule.Create()  
  }
  # Set Schedule for sp_purge_jobhistory to once a week on Sunday Evening

  $Job = $Jobs|Where-Object -FilterScript {
    $_.Name -eq 'sp_purge_jobhistory'
  }
  if ($Null -eq $Job) 
  {
    Write-Output -InputObject 'No Job with that name' 
    break
  }
  else
  {
    $Schedule = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.JobSchedule -ArgumentList ($Job, 'Weekly Sunday - Evening ')
    $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
    $Schedule.ActiveEndTimeOfDay = '23:59:59'
    $Schedule.FrequencyTypes = 'Weekly' 
    $Schedule.FrequencyRecurrenceFactor = 1 
    $Schedule.FrequencyInterval = 1 
    $Schedule.ActiveStartDate = Get-Date  
    $Schedule.ActiveStartTimeOfDay = '19:16:00'
    $Schedule.IsEnabled = $true
    $Schedule.Create()  
  }
}
