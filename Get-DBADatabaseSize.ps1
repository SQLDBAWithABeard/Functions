<#PSScriptInfo

.VERSION 1.0

.GUID 12e32036-c18e-4bce-b74f-3270c8f216c3

.AUTHOR Rob Sewell

.COMPANYNAME Sewells Consulting

.COPYRIGHT Rob Sewell - please credit Rob Sewell - https://sqldbawithbeard.com if used

.DESCRIPTION returns a database smo object of the size of the databases on an instance in Mb and enables top N if required

.TAGS SQL,Database, Size

.LICENSEURI 

.PROJECTURI

.ICONURI 

.EXTERNALMODULEDEPENDENCIES sqlserver

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES Initial
#>
function Get-DBADatabaseSize
{
<#
.Synopsis
   Gets the size of the databases on an instance in Mb
.DESCRIPTION
   returns a database smo object of the size of the databases on an instance in Mb and enables top N if required
.EXAMPLE
   Get-DBADatabaseSize -Instance SERVER

   Returns the database names and sizes in Mb ordered by size for all of the databases on SERVER
.EXAMPLE
   Get-DBADatabaseSize -Instance SERVER -Top 3

   Returns the database names and sizes in Mb ordered by size for the 3 largest databases on SERVER
.EXAMPLE
   Get-DBADatabaseSize SERVER  3

   Returns the database names and sizes in Mb ordered by size for the 3 largest databases on SERVER
.OUTPUTS
   Database object
.NOTES
   AUTHOR - Rob Sewell https://sqldbawithabeard.com
   DATE - 30/10/2016
#>
#Requires -Version 5
    [OutputType([object])]
    param(
    ## The Name of the instance
    [Parameter(Position=0,Mandatory=$true)]
    [string]$Instance,
    [Parameter(Position=1,Mandatory=$false)]
    ## The number of results to show
    [int]$Top
    )
    [void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );
    $srv = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $Instance
    if(!$Top)
    {
        $srv.databases.Where{$_.IsAccessible -eq $true} | Sort-Object -Descending size|Select-Object Name , Size
    }
    else
    {
        $srv.databases.Where{$_.IsAccessible -eq $true} | Sort-Object -Descending size|Select-Object Name , Size -First $Top
    }
}