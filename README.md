# Functions
Contains useful functions that I use and am able to share. 

[Get-DriveSize](Get-DriveSize.ps1)      -   Returns the Drive or Volume Name, Label, Size in Gb, Free Space in GB and Free space as a                                                percentage of drives and mount points on local and remote servers

[Test-SQLDefault](Test-SQLDefaults.ps1)  -   Runs a series of Pester tests against a SQL Instance or an array of SQL Instances. Should be                                             easy to customise to your own environments required defaults 

[Show-DatabasesOnServer](Show-DatabasesOnServer.ps1) - Returns the Name and sizes of databases on a server or array of servers

[Set-OlaJobSchedule](Set-OlaJobsSchedule.ps1) - Sets the agent job schedule for the jobs created by Ola Hallengrens Maintenance plan

[When-WillSQLComplete](When-WillSQLComplete.ps1) -  Quick function to check progress of SQL Commands via sys.dm_exec_requests. Useful for                                                     DBCC, Backup, Restore and indexing progress

[Test-OLAInstance](Test-OLAInstance.ps1) - Wrapper to call a Pester Test script [Test-OLA](Test-OLA.ps1) to test Ola Hallengren Maintenance Solution is installed correctly

