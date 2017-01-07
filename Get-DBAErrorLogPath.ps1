<#PSScriptInfo

.VERSION 1.0

.GUID ed045950-8973-45e1-bb1d-af4464fd1eed

.AUTHOR Rob Sewell

.COMPANYNAME Sewells Consulting

.COPYRIGHT Rob Sewell - please credit Rob Sewell - https://sqldbawithbeard.com if used

.DESCRIPTION returns the SQL or Agent Error log paths for a SQL Server

.TAGS SQL,SQL Agent, ErrorLog, Path

.LICENSEURI 

.PROJECTURI

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES Initial
#>
function Get-DBAErrorLogPath
{
<#
.Synopsis
   Returns the Error Log PAths for a SQL Server
.DESCRIPTION
   returns the SQL or Agent Error log paths for a SQL Server
.EXAMPLE
   Get-DBAErrorLogPath -Instance SERVER

   Returns the Error Log Path for a SQL Server
.EXAMPLE
   Get-DBADatabaseSize -Instance SERVER -Agent

   Returns the SQL and Agent Log Error Paths for the SERVER
.EXAMPLE
   Get-DBADatabaseSize SERVER 

   Returns the Error Log Path for a SQL Server
.OUTPUTS
   String
.NOTES
   AUTHOR - Rob Sewell https://sqldbawithabeard.com
   DATE - 11/11/2016
#>
#Requires -Version 5
    [OutputType([string])]
    param(
    ## The Name of the instance
    [Parameter(Position=0,Mandatory=$true)]
    [string]$Instance,
    ## Display the AgentLog path as well
    [switch]$Agent
    )
    [void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );
    $srv = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $Instance
    Write-Output "Error Log Path - $($srv.ErrorLogPath)"
    if($Agent)
    {
    Write-Output "Agent Error Log Path - $($srv.JobServer.ErrorLogFile)"
    }
}