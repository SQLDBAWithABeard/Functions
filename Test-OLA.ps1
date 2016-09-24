## This script will check the status of the SQL Servers OLA set up including all agent jobs, folders and existence of backup files
## Whilst you can call this script directly using Invoke-Pester and a script block as shown below it should be called with
##
## function Test-OLAInstance
##
##
## To find out more Get-Help Test-OLAInstance
##
##$Script = @{
##Path = $Path;
##Parameters = @{ Instance = Instance;
##CheckForBackups =  $true;
##CheckForDBFolders =  $true;
##JobSuffix = 'BackupShare1'; 
##Share = '\\Server1\BackupShare1'
##NoDatabaseRestoreCheck= $true;
##DontCheckJobOutcome = $true}}
##}
##Invoke-Pester -Script $Script
## Author - Rob Sewell https://sqldbawithabeard.com @SQLDBAWithBeard
## Date - 06/09/2016
#Requires –Version 4
#Requires -Modules Pester
#Requires -Modules sqlserver

[CmdletBinding()]
## Pester Test to check OLA
Param(
$Instance,
$CheckForBackups,
$CheckForDBFolders,
$JobSuffix ,
$Share ,
[switch]$NoDatabaseRestoreCheck,
[switch]$DontCheckJobOutcome 
)

foreach($server in $Instance)
{

$ServerName = $Server.Split('\')[0]
$InstanceName = $Server.Split('\')[1]
$ServerName = $ServerName.ToUpper()
Describe "Testing $Server Backup solution" {
    BeforeAll {
    $Jobs = Get-SqlAgentJob -ServerInstance $Server
    $srv = New-Object Microsoft.SQLServer.Management.SMO.Server $Server 
    $dbs = $Srv.Databases.Where{$_.status -eq 'Normal'}.name
    $LSJobs = $srv.jobserver.jobs.where{$_.name -like 'LSBackup*'}.Name
    $LSDatabases = @()
    foreach ($Job in $LSJobs)
    {
        $LSDatabases += $Job.Split('_')[1]
    } 

    if($InstanceName)
    {
        $DisplayName =  "SQL Server Agent ($InstanceName)"
        $Folder = $ServerName + '$' + $InstanceName
    }
    else
    {
        $DisplayName =  "SQL Server Agent (MSSQLSERVER)"
        $Folder = $ServerName
    }
        if($CheckForBackups -eq $true)
    {
      $CheckForDBFolders -eq $true
    }
    }

        if($Share.StartsWith('\\') -eq $False)
    {
      $UNC = $Share.Replace(':','$')
      $Root = '\\' + $ServerName + '\' + $UNC + '\' + $Folder
    }
    else
    {
    $Root = $Share + '\' + $Folder
    }
     
    Context "New Backup Jobs on $server" {
        It "Agent should be running" {
        (Get-service -ComputerName $ServerName -DisplayName $DisplayName).Status | Should Be 'Running'
        }
        $Jobs = $Jobs.Where{($_.Name -like 'DatabaseBackup - SYSTEM_DATABASES - FULL*' + $JobSuffix + '*') -or ($_.Name -like 'DatabaseBackup - USER_DATABASES - FULL*' + $JobSuffix + '*') -or ($_.Name -like 'DatabaseBackup - USER_DATABASES - DIFF*' + $JobSuffix + '*') -or ($_.Name -like 'DatabaseBackup - USER_DATABASES - LOG*' + $JobSuffix + '*')}
        foreach($job in $Jobs)
        {
          $JobName = $Job.Name
          It "$JobName Job Exists" {
          $Job | Should Not BeNullOrEmpty
          }
          It "$JobName Job is enabled" {
          $job.IsEnabled | Should Be 'True'
          }
          It "$JobName Job has schedule" {
          $Job.HasSchedule | Should Be 'True'
          }
          if($DontCheckJobOutcome -eq $false)
          {
            It "$JobName Job succeeded" {
            $Job.LastRunOutCome | Should Be 'Succeeded'
            }
          }
          if($NoDatabaseRestoreCheck -eq $false)
          {
            It "$JobName Job has 2 JobSteps" {
            $Job.Jobsteps.Count | Should Be 2
            }
            It "$JobName Job has Generate Restore Script Job Step" {
            $Job.JobSteps[1].Name | Should  Be 'Generate Restore Script'
            }
          }
        }# foreach jobs
        } # end context new backup jobs
    Context "Other Maintenance Jobs on $Instance" {
        $Jobs = $Jobs.Where{($_.Name -eq 'DatabaseIntegrityCheck - SYSTEM_DATABASES') -or ($_.Name -eq 'DatabaseIntegrityCheck - USER_DATABASES') -or ($_.Name -eq 'IndexOptimize - USER_DATABASES')}
          foreach($job in $Jobs)
          {
            $JobName = $Job.Name
            It "$JobName Job Exists" {
            $Job | Should Not BeNullOrEmpty
            }
            It "$JobName Job is enabled" {
            $job.IsEnabled | Should Be 'True'
            }
            It "$JobName Job has schedule" {
            $Job.HasSchedule | Should Be 'True'
            }
            if($DontCheckJobOutcome -eq $false)
            {
              It "$JobName Job succeeded" {
              $Job.LastRunOutCome | Should Be 'Succeeded'
              }
            }
          }# foreach jobs
       
    } # end context other maintenanace jobs
    Context "OLA cleanup jobs on $Instance" {
        $Jobs = $Jobs.Where{($_.Name -eq 'Output File Cleanup') -or ($_.Name -eq 'CommandLog Cleanup') -or ($_.Name -eq 'sp_delete_backuphistory') -or ($_.Name -eq 'sp_purge_jobhistory')}
         foreach($job in $Jobs)
          {
            $JobName = $Job.Name
            It "$JobName Job Exists" {
            $Job | Should Not BeNullOrEmpty
            }
            It "$JobName Job is enabled" {
            $job.IsEnabled | Should Be 'True'
            }
            It "$JobName Job has schedule" {
            $Job.HasSchedule | Should Be 'True'
            }
            if($DontCheckJobOutcome -eq $false)
            {
              It "$JobName Job succeeded" {
              $Job.LastRunOutCome | Should Be 'Succeeded'
              }
            }
          }# foreach jobs           
        } # end ola clean up jobs  
    Context "$Share Share For $Server" {
        It "Should have the root folder $Root" {
        Test-Path $Root | Should Be $true
        }
        if($NoDatabaseRestoreCheck -eq $false)
        {
        It "Database Restore Text file exists" {
        $RestoreTXT = $Root + '\DatabaseRestore.txt'
        $Check = Test-Path $RestoreTXT 
        $Check| Should Be $true
        }
        if ($Check-eq $true)
        {
        It "Database Restore Text is less than 30 minutes old" {
        ((Get-ChildItem $RestoreTXT).LastWriteTime -lt (Get-Date).AddMinutes(-30)) | Should Be $true
        }
        }
        }
        }
                foreach($db in $dbs.Where{$_ -ne 'tempdb'})
        {
          if($Srv.VersionMajor -ge 11)
            {
                If($srv.Databases[$db].AvailabilityGroupName)
                {
                     $AG = $srv.Databases[$db].AvailabilityGroupName
                     $Cluster = $srv.ClusterName
                     $OLAAg = $Cluster + '$' + $AG
                     $Root =  $Share + '\' + $OlaAG 
                }
                else
                {
                    $Root =  $Share + '\' + $Server
                }
            }
            $db = $db.Replace(' ','')
            $Dbfolder = $Root + "\$db"
            $Full = $Dbfolder + '\FULL'
            $Diff = $Dbfolder + '\DIFF'
            $Log  = $Dbfolder + '\LOG'
            If($CheckForDBFolders -eq $True)
            {
            Context "Folder Check for $db on $Server on $Share" {
            It "Should have a folder for $db database" {
            Test-Path $Dbfolder |Should Be $true
            }
            if($Db -notin ('master','msdb','model') -and ($Srv.Databases[$db].RecoveryModel -ne 'Simple') -and ( $LSDatabases -notcontains $db))
            {
            It "Has a Full Folder" {
                [System.IO.Directory]::Exists($Full) | Should Be $True
            }
            It "Has a Diff Folder" {
                [System.IO.Directory]::Exists($Diff) | Should Be $True
            }
            It "Has a Log Folder" {
                [System.IO.Directory]::Exists($Log) | Should Be $True
            }
            } #
            elseif(($Srv.Databases[$db].RecoveryModel -eq 'Simple') -and $Db -notin ('master','msdb','model') -or ( $LSDatabases -contains $db) )
            {
            It "Has a Full Folder" {
            [System.IO.Directory]::Exists($Full) | Should Be $True
            }
            It "Has a Diff Folder" {
                [System.IO.Directory]::Exists($Diff) | Should Be $True
            }           
            } #
            else
            {
            It "Has a Full Folder" {
                [System.IO.Directory]::Exists($Full) | Should Be $True
            }
            }#
            } # End Check for db folders
            }
            If($CheckForBackups -eq $true)
            {
            Context " File Check For $db on $Server on $Share" {  
                    $Fullcreate = [System.IO.Directory]::GetCreationTime($Full)
                    $FullWrite = [System.IO.Directory]::GetLastWriteTime($Full) 
                if($Fullcreate -eq $FullWrite)
                    {
                        It "Has Files in the FULL folder for $db" {
                        Get-ChildItem $Full\*.bak | Should Not BeNullOrEmpty
                        }
                    }
                    else
                    {
                It "Has Files in the FULL folder for $db" {
                    $FullCreate | Should BeLessThan $FullWrite
                    }
                }
                It "Full File Folder was written to within the last 7 days" {
                $Fullwrite |Should BeGreaterThan (Get-Date).AddDays(-7)
                }
                if($Db -notin ('master','msdb','model'))
                {
                    $Diffcreate = [System.IO.Directory]::GetCreationTime($Diff)
                    $DiffWrite = [System.IO.Directory]::GetLastWriteTime($Diff)
                    if($Diffcreate -eq $DiffWrite)
                    {
                        It "Has Files in the DIFF folder for $db" {
                        Get-ChildItem $Diff\*.bak | Should Not BeNullOrEmpty
                        }
                    }
                    else
                    {
                    It "Has Files in the DIFF folder for $db" {
                    $DiffCreate | Should BeLessThan $DiffWrite
                        }
                    }
 
                It "Diff File Folder was written to within the last 24 Hours" {
                $Diffwrite |Should BeGreaterThan (Get-Date).AddHours(-24)
                }
                }
                if($Db -notin ('master','msdb','model') -and ($Srv.Databases[$db].RecoveryModel -ne 'Simple') -and ( $LSDatabases -notcontains $db))
            {
                    $Logcreate = [System.IO.Directory]::GetCreationTime($Log)
                    $LogWrite = [System.IO.Directory]::GetLastWriteTime($Log)
                    if($Logcreate -eq $LogWrite)
                    {
                        It "Has Files in the LOG folder for $db" { 
                        Get-ChildItem $Log\*.trn | Should Not BeNullOrEmpty
                        }
                    }
                    else
                    {
                        It "Has Files in the LOG folder for $db" { 
                        $LogCreate | Should BeLessThan $LogWrite
                        }
                    }
                    It "Log File Folder was written to within the last 30 minutes" {
                    $Logwrite |Should BeGreaterThan (Get-Date).AddMinutes(-30) 
                    }
                }# Simple Recovery
            }
            }# Check for backups

    } # End share context
}#end describe
}

