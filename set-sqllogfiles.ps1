 function Set-SQLLogFiles
 {
 <#
.Synopsis
   Sets the number of Log files for a single or group of SQL Servers

.DESCRIPTION
   Uses SMO to set the number of Log files for a single or group of SQL Servers
      
.PARAMETER Instances
The SQL Server Instance or an array of instances to change

.PARAMETER Number
The number of logfiles to set

.EXAMPLE
   Set-SQLLogFiles -instances Fade2Black -Number 20

   Sets the number of SQL Server log files to 20 on the instance Fade2Black
.EXAMPLE
   $Servers = 'Fade2Black','JusticeForAll','MasterOfPuppets'
   Set-SQLLogFiles -instances $Servers -Number 20

   Sets the number of SQL Server log files to 20 on the instances 'Fade2Black','JusticeForAll','MasterOfPuppets'
.NOTES
    Author - Rob Sewell SQLDBAWithABeard.com
#>
 param(
 [object]$instances,
 [ValidateRange(0,99)]
 [int]$Number
 )
 [void][reflection.assembly]::LoadWithPartialName( 'Microsoft.SqlServer.Smo' )
    foreach($Server in $Instances)
    {
        try
        {
            $srv = New-Object Microsoft.SqlServer.Management.Smo.Server $server
            $srv.Settings.NumberOfLogFiles = $Number
            $srv.Alter()
        }
        catch
        {
            Write-Warning "Eailed to set Log Fiels on $Server - Run `$error[0]|fl -force to find the error"
            continue
        }
    }
 }