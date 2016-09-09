## This script will check the status of the SQL Servers OLA set up including all agent jobs, folders and existence of backup files
## Whilst you can call this script directly using Invoke-Pester and a script block as shown below it should be called with
##
## function Test-OLAInstance
##
##
## To find out more Get-Help Test-OLAInstance
##
## $Script = @{
## Path = $Path;
## Parameters = @{ Instance = Instance;
## CheckForBackups =  $true;
## CheckForDBFolders =  $true;
## JobSuffix = 'BackupShare1'; 
## Share = '\\Server1\BackupShare1'}
## }
## Invoke-Pester -Script $Script
## Author - Rob Sewell https://sqldbawithabeard.com @SQLDBAWithBeard
## Date - 06/09/2016

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
$NoDatabaseRestoreTextFileCheck
)

foreach($server in $Instance)
{
if($Server.contains('MSSQLSERVER'))
{
$Server = $Server.Split('\')[0]
}
$Server = $Server.ToUpper()
Describe "Testing $Server Backup solution" {
    BeforeAll {
    $Jobs = Get-SqlAgentJob -ServerInstance $Server
    $Root = $Share + '\' + $Server
    $srv = New-Object Microsoft.SQLServer.Management.SMO.Server $Server 
    $dbs = $Srv.Databases.Where{$_.status -eq 'Normal'}.name
    $SysFull = $Jobs.Where{$_.Name -like 'DatabaseBackup - SYSTEM_DATABASES - FULL*' + $JobSuffix + '*'}
    $UserFull = $Jobs.Where{$_.Name -like 'DatabaseBackup - USER_DATABASES - FULL*' + $JobSuffix + '*'}
    $UserDiff = $Jobs.Where{$_.Name -like 'DatabaseBackup - USER_DATABASES - DIFF*' + $JobSuffix + '*'}
    $UserLog = $Jobs.Where{$_.Name -like 'DatabaseBackup - USER_DATABASES - LOG*' + $JobSuffix + '*'} 
    }
    Context "New Backup Jobs on $Server" {
        It "Agent should be running" {
        (Get-service -ComputerName $Server SQLSERVERAGENT).Status | Should Be 'Running'
        }
        foreach($job in $SysFull,$UserFull,$UserDiff,$USerLog)
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
        It "$JobName Job succeeded" {
        $Job.LastRunOutCome | Should Be 'Succeeded'
        }
        It "$JobName Job has 2 JobSteps" {
        $Job.Jobsteps.Count | Should Be 2
        }
        It "$JobName Job has Generate Restore Script Job Step" {
        $Job.JobSteps[1].Name | Should  Be 'Generate Restore Script'
        }
        }# foreach jobs
        } # end context new backup jobs
    Context "Other Maintenance Jobs on $Server" {
        It "Should have System Database Integrity Check Job" {
        $Jobs.Where{$_.Name -eq 'DatabaseIntegrityCheck - SYSTEM_DATABASES'} | Should Not BeNullOrEmpty
        }
        It "Should have User Database Integrity Check Job" {
        $Jobs.Where{$_.Name -eq 'DatabaseIntegrityCheck - USER_DATABASES'} | Should Not BeNullOrEmpty
        }
        It "Should have User Database Index Optimisation Job" {
        $Jobs.Where{$_.Name -eq 'IndexOptimize - USER_DATABASES'} | Should Not BeNullOrEmpty
        }
       
    } # end context other maintenanace jobs
    Context "OLA cleanup jobs on $Server" {
        It "Should have Output File Cleanup Job" {
        $Jobs.Where{$_.Name -eq 'Output File Cleanup'} | Should Not BeNullOrEmpty
        }
        It "Should have CommandLog Cleanup Job" {
        $Jobs.Where{$_.Name -eq 'CommandLog Cleanup'} | Should Not BeNullOrEmpty
        }
        It "Should have sp_delete_backuphistory Job" {
        $Jobs.Where{$_.Name -eq 'sp_delete_backuphistory'} | Should Not BeNullOrEmpty
        }
        It "Should have sp_purge_jobhistory Job" {
        $Jobs.Where{$_.Name -eq 'sp_purge_jobhistory'} | Should Not BeNullOrEmpty
        }                
        
    } # end ola clean up jobs 
    Context "$Share Share on $Server" {
        It "Should have the root folder $Root" {
        Test-Path $Root | Should Be $true
        }
        if($NoDatabaseRestoreTextFileCheck -eq $false)
        {
        It "Database Restore Text file exists" {
        $RestoreTXT = $Root + '\DatabaseRestore.txt'
        Test-Path $RestoreTXT | Should Be $true
        }
        It "Database Restore Text is less than 30 minutes old" {
        ((Get-ChildItem $RestoreTXT).LastWriteTime -gt (Get-Date).AddMinutes(-30)) | Should Be $true
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
            It "Should have a folder for $db database" {
            Test-Path $Dbfolder |Should Be $true
            }
            if($Db -notin ('master','msdb','model') -and ($Srv.Databases[$db].RecoveryModel -ne 'Simple'))
            {
            It "has Full Diff and Log Folders" {
            (Test-Path $full , $log, $Diff).Where{$_ -eq $true}.Count | Should Be 3
            }
            } #
            elseif(($Srv.Databases[$db].RecoveryModel -eq 'Simple') -and $Db -notin ('master','msdb','model'))
            {
            It "has Full and Diff Folders" {
            (Test-Path $full , $Diff).Where{$_ -eq $true}.Count | Should Be 2
            }            
            } #
            else
            {
            It "has a Full Folder" {
            Test-Path $full | Should Be $true
            } 
            }#
            } # End Check for db folders
            If($CheckForBackups -eq $true)
            {
                It "Has Full Backups in the folder for $db" {
                Get-ChildItem $Full\*.bak | Select-Object -First 1  | Should Not BeNullOrEmpty
                }
                if($Db -notin ('master','msdb','model'))
                {
                It "Has Diff Backups in the folder for $db" {
                Get-ChildItem $Diff\*.bak | Select-Object -First 1 | Should Not BeNullOrEmpty
                }
                }
                if (($Srv.Databases[$db].RecoveryModel -ne 'Simple') -and ($Db -notin ('master','msdb','model')))
                {
                    It "Has Log Backups in the folder for $db" {
                    Get-ChildItem $Log\*.trn | Select-Object -First 1 | Should Not BeNullOrEmpty
                }
                }# Simple Recovery
            }# Check for backups
        }

    } # End share context
}#end describe
}
