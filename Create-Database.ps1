

 #############################################################################################
#
# NAME: Create-Database.ps1
# AUTHOR: Rob Sewell http://sqldbawithabeard.com
# DATE:08/09/2013
#
# COMMENTS: Load function for creating a database
#           Only Server and DB Name are mandatory the rest will be set to small defaults
#
# USAGE:  Create-Database -Server Fade2black -DBName Test35 -SysFileSize 10 -UserFileSize 15 -LogFileSize 20
# -UserFileGrowth 7 -UserFileMaxSize 150 -LogFileGrowth 8 -LogFileMaxSize 250 -DBRecModel FULL
# ————————————————————————


Function Create-Database 
{
Param(
[Parameter(Mandatory=$true)]
[String]$Server ,
[Parameter(Mandatory=$true)]
[String]$DBName,
[Parameter(Mandatory=$false)]
[int]$SysFileSize = 5,
[Parameter(Mandatory=$false)]
[int]$UserFileSize = 25,
[Parameter(Mandatory=$false)]
[int]$LogFileSize = 25,
[Parameter(Mandatory=$false)]
[int]$UserFileGrowth = 5,
[Parameter(Mandatory=$false)]
[int]$UserFileMaxSize =100,
[Parameter(Mandatory=$false)]
[int]$LogFileGrowth = 5,
[Parameter(Mandatory=$false)]
$LogFileMaxSize = 100,
[Parameter(Mandatory=$false)]
[String]$DBRecModel = 'FULL'
)

try {
    # Set server object
    $srv = New-Object ('Microsoft.SqlServer.Management.SMO.Server') $server
    if($srv.Databases[$DBName])
	{
	Write-Warning "$DBName already exists on $Server"
	continue
	}
	$DB = $srv.Databases[$DBName]
    # Define the variables
    # Set the file sizes (sizes are in KB, so multiply here to MB)
    $SysFileSize = [double]($SysFileSize * 1024.0)
    $UserFileSize = [double] ($UserFileSize * 1024.0)
    $LogFileSize = [double] ($LogFileSize * 1024.0)
    $UserFileGrowth = [double] ($UserFileGrowth * 1024.0)
    $UserFileMaxSize = [double] ($UserFileMaxSize * 1024.0)
    $LogFileGrowth = [double] ($LogFileGrowth * 1024.0)
    $LogFileMaxSize = [double] ($LogFileMaxSize * 1024.0)
   

    Write-Output "Creating database: $DBName on $Server"
 
    # Set the Default File Locations
    $DefaultDataLoc = $srv.Settings.DefaultFile
    $DefaultLogLoc = $srv.Settings.DefaultLog
 
    # If these are not set, then use the location of the master db mdf/ldf
    if ($DefaultDataLoc.Length -EQ 0) {$DefaultDataLoc = $srv.Information.MasterDBPath}
    if ($DefaultLogLoc.Length -EQ 0) {$DefaultLogLoc = $srv.Information.MasterDBLogPath}
 
    # new database object
    $DB = New-Object ('Microsoft.SqlServer.Management.SMO.Database') ($srv, $DBName)
 
    # new filegroup object
    $PrimaryFG = New-Object ('Microsoft.SqlServer.Management.SMO.FileGroup') ($DB, 'PRIMARY')
    # Add the filegroup object to the database object
    $DB.FileGroups.Add($PrimaryFG )
 
    # Best practice is to separate the system objects from the user objects.
    # So create a seperate User File Group
    $UserFG= New-Object ('Microsoft.SqlServer.Management.SMO.FileGroup') ($DB, 'UserFG')
    $DB.FileGroups.Add($UserFG)
 
    # Create the database files
    # First, create a data file on the primary filegroup.
    $SystemFileName = $DBName + "_System"
    $SysFile = New-Object ('Microsoft.SqlServer.Management.SMO.DataFile') ($PrimaryFG , $SystemFileName)
    $PrimaryFG.Files.Add($SysFile)
    $SysFile.FileName = $DefaultDataLoc + $SystemFileName + ".MDF"
    $SysFile.Size = $SysFileSize
    $SysFile.GrowthType = "None"
    $SysFile.IsPrimaryFile = 'True'
 
    # Now create the data file for the user objects
    $UserFileName = $DBName + "_User"
    $UserFile = New-Object ('Microsoft.SqlServer.Management.SMO.Datafile') ($UserFG, $UserFileName)
    $UserFG.Files.Add($UserFile)
    $UserFile.FileName = $DefaultDataLoc + $UserFileName + ".NDF"
    $UserFile.Size = $UserFileSize
    $UserFile.GrowthType = "KB"
    $UserFile.Growth = $UserFileGrowth
    $UserFile.MaxSize = $UserFileMaxSize
 
    # Create a log file for this database
    $LogFileName = $DBName + "_Log"
    $LogFile = New-Object ('Microsoft.SqlServer.Management.SMO.LogFile') ($DB, $LogFileName)
    $DB.LogFiles.Add($LogFile)
    $LogFile.FileName = $DefaultLogLoc + $LogFileName + ".LDF"
    $LogFile.Size = $LogFileSize
    $LogFile.GrowthType = "KB"
    $LogFile.Growth = $LogFileGrowth
    $LogFile.MaxSize = $LogFileMaxSize
 
    #Set the Recovery Model
    $DB.RecoveryModel = $DBRecModel
    #Create the database
    $DB.Create()
 
    #Make the user filegroup the default
    $UserFG = $DB.FileGroups['UserFG']
    $UserFG.IsDefault = $true
    $UserFG.Alter()
    $DB.Alter()

    Write-Output " $DBName Created on $Server"

} Catch
{
   Write-Warning " An Error Occured Run  `$error[0] | fl * -force to get the full details"
}
    }