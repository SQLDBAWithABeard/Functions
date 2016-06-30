<# 
.SYNOPSIS  
     Shows the Instances and the Port Numbers on a SQL Server
.DESCRIPTION 
    This function will show the Instances and the Port Numbers on a SQL Server using WMI
.PARAMETER Server
    The Server Name
.EXAMPLE 
    Get-SQLInstancesPort Fade2Black

    This will display the instances and the port numbers on the server Fade2Black


.NOTES 
    AUTHOR: Rob Sewell sqldbawithabeard.com 
    DATE: 22/04/2015 
#> 
#version 1.2.0
function Get-SQLInstancesPort
{

param
(
[Parameter(Mandatory)]
[string]$Server 
)

[system.reflection.assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')|Out-Null
[system.reflection.assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement')|Out-Null
$mc = new-object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $Server
$Instances = $mc.ServerInstances
foreach($Instance in $Instances)
    {
    $port = @{Name ='Port'; Expression = {$_.ServerProtocols['Tcp'].IPAddresses['IPAll'].IPAddressProperties['TcpPort'].Value}}
    $Parent = @{Name = 'Parent'; Expression ={$_.Parent.Name}}
    $Name = $Instance.Name
    $Service = (Get-Service -DisplayName *`($Name`) )[0]
    $Status = @{Name = 'Status'; Expression = {$Service.Status}}
    $StartMode  = @{Name = 'StartMode'; Expression = {$Service.StartType}}
    $Instance |Select-Object $Parent,Name,$Port, $Status, $StartMode 
    }
}