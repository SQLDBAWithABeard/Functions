## This script will check the status of the SQL Servers Net App set up including all agent jobs, folders and existence of backup files
## Whilst you can call this script directly using Invoke-Pester and a script block as shown below it should be called with
##
## function Test-OLANetAppInstance
##
##
## To find out more Get-Help Test-OLANetAppInstance
##
## $Script = @{
## Path = $Path;
## Parameters = @{ Instance = $Instance;
## CheckForBackups =  $CheckForBackups;
## CheckForDBFolders =  $CheckForDBFolders;
## JobSuffix = $JobSuffix; 
## Share = $Share}
## }
## Invoke-Pester -Script $Script
## Author - Rob Sewell sqldbawithabeard
## Date - 06/09/2016

#Requires -Modules Pester
#Requires -Modules sqlserver

[CmdletBinding()]
## Pester Test to check OLA NetApp
Param(
$Instance,
$CheckForBackups,
$CheckForDBFolders,
$JobSuffix ,
$Share ,
[switch]$NoDatabaseRestoreTextFileCheck
)

foreach($server in $Instance)
{
$Server = $server.ToUpper()
Describe "Testing $Server Backup solution" {
    BeforeAll {
    $Jobs = Get-SqlAgentJob -ServerInstance $Server
    $Root = '\\hesto03.mgmt.local\' + $Share + '\' + $Server
    $srv = New-Object Microsoft.SQLServer.Management.SMO.Server $Server 
    $dbs = $Srv.Databases.Where{$_.status -eq 'Normal'}.name
	$LSJobs = $srv.jobserver.jobs.where{$_.name -like 'LSBackup*'}.Name
    $LSDatabases = @()
    foreach ($Job in $LSJobs)
    {
        $LSDatabases += $Job.Split('_')[1]
    }
    $SysFull = $Jobs.Where{$_.Name -like 'DatabaseBackup - SYSTEM_DATABASES - FULL*' + $JobSuffix + '*'}
    $UserFull = $Jobs.Where{$_.Name -like '*DatabaseBackup - USER_DATABASES - FULL*' + $JobSuffix + '*'}
    $UserDiff = $Jobs.Where{$_.Name -like '*DatabaseBackup - USER_DATABASES - DIFF*' + $JobSuffix + '*'}
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
			$Check = Test-Path $RestoreTXT 
        $Check| Should Be $true
        }
		if($Check -eq $true)
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
                     $Root =   '\\hesto03.mgmt.local\' + $Share + '\' + $OlaAG 
                     $Root
                }
                else
                {
                    $Root = '\\hesto03.mgmt.local\' + $Share + '\' + $Server
                }
            }
            $db = $db.Replace(' ','')
            $Dbfolder = $Root + "\$db"
            $Full = $Dbfolder + '\FULL'
            $Diff = $Dbfolder + '\DIFF'
            $Log  = $Dbfolder + '\LOG'
            If($CheckForDBFolders -eq $True)
            {
            Context "Folder Check for $db on $server on $Share" {
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
                It "Has Files in the FULL folder for $db" {
                    $FullCreate | Should BeLessThan $FullWrite
                }
                It "Full File Folder was written to within the last 7 days" {
                $Fullwrite |Should BeGreaterThan (Get-Date).AddDays(-7)
                }
                if($Db -notin ('master','msdb','model'))
                {
                    $Diffcreate = [System.IO.Directory]::GetCreationTime($Diff)
                    $DiffWrite = [System.IO.Directory]::GetLastWriteTime($Diff)
                It "Has Files in the DIFF folder for $db" {
                    $DiffCreate | Should BeLessThan $DiffWrite
                }
                It "Diff File Folder was written to within the last 24 Hours" {
                $Diffwrite |Should BeGreaterThan (Get-Date).AddHours(-24)
                }
                }
                if($Db -notin ('master','msdb','model') -and ($Srv.Databases[$db].RecoveryModel -ne 'Simple') -and ( $LSDatabases -notcontains $db))
            {
                    $Logcreate = [System.IO.Directory]::GetCreationTime($Log)
                    $LogWrite = [System.IO.Directory]::GetLastWriteTime($Log)
                    It "Has Files in the LOG folder for $db" { 
                    $LogCreate | Should BeLessThan $LogWrite
                    }
                    It "Log File Folder was written to within the last 30 minutes" {
                    $Logwrite |Should BeGreaterThan (Get-Date).AddMinutes(-30) 
                    }
                }# Simple Recovery
            }
            }# Check for backups

    } # End dbbronze share context
}#end describe
}